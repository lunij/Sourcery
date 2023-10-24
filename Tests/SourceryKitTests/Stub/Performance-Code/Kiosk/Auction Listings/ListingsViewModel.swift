import Foundation
import RxSwift

typealias ShowDetailsClosure = (SaleArtwork) -> Void
typealias PresentModalClosure = (SaleArtwork) -> Void

protocol ListingsViewModelType {
    var auctionID: String { get }
    var syncInterval: TimeInterval { get }
    var pageSize: Int { get }
    var logSync: (Date) -> Void { get }
    var numberOfSaleArtworks: Int { get }

    var showSpinner: Observable<Bool>! { get }
    var gridSelected: Observable<Bool>! { get }
    var updatedContents: Observable<NSDate> { get }

    var scheduleOnBackground: (_ observable: Observable<Any>) -> Observable<Any> { get }
    var scheduleOnForeground: (_ observable: Observable<[SaleArtwork]>) -> Observable<[SaleArtwork]> { get }

    func saleArtworkViewModel(atIndexPath indexPath: IndexPath) -> SaleArtworkViewModel
    func showDetailsForSaleArtwork(atIndexPath indexPath: IndexPath)
    func presentModalForSaleArtwork(atIndexPath indexPath: IndexPath)
    func imageAspectRatioForSaleArtwork(atIndexPath indexPath: IndexPath) -> CGFloat?
    func hasEstimateForSaleArtwork(atIndexPath indexPath: IndexPath) -> Bool
}

// Cheating here, should be in the instance but there's only ever one instance, so ¯\_(ツ)_/¯
private let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)

class ListingsViewModel: NSObject, ListingsViewModelType {
    // These are private to the view model – should not be accessed directly
    fileprivate var saleArtworks = Variable([SaleArtwork]())
    fileprivate var sortedSaleArtworks = Variable<[SaleArtwork]>([])

    let auctionID: String
    let pageSize: Int
    let syncInterval: TimeInterval
    let logSync: (Date) -> Void
    var scheduleOnBackground: (_ observable: Observable<Any>) -> Observable<Any>
    var scheduleOnForeground: (_ observable: Observable<[SaleArtwork]>) -> Observable<[SaleArtwork]>

    var numberOfSaleArtworks: Int {
        sortedSaleArtworks.value.count
    }

    var showSpinner: Observable<Bool>!
    var gridSelected: Observable<Bool>!
    var updatedContents: Observable<NSDate> {
        sortedSaleArtworks
            .asObservable()
            .map { $0.count > 0 }
            .ignore(value: false)
            .map { _ in NSDate() }
    }

    let showDetails: ShowDetailsClosure
    let presentModal: PresentModalClosure
    let provider: Networking

    init(
        provider: Networking,
        selectedIndex: Observable<Int>,
        showDetails: @escaping ShowDetailsClosure,
        presentModal: @escaping PresentModalClosure,
        pageSize: Int = 10,
        syncInterval: TimeInterval = SyncInterval,
        logSync: @escaping (Date) -> Void = ListingsViewModel.DefaultLogging,
        scheduleOnBackground: @escaping (_ observable: Observable<Any>) -> Observable<Any> = ListingsViewModel.DefaultScheduler(onBackground: true),
        scheduleOnForeground: @escaping (_ observable: Observable<[SaleArtwork]>) -> Observable<[SaleArtwork]> = ListingsViewModel.DefaultScheduler(onBackground: false),
        auctionID: String = AppSetup.sharedState.auctionID
    ) {
        self.provider = provider
        self.auctionID = auctionID
        self.showDetails = showDetails
        self.presentModal = presentModal
        self.pageSize = pageSize
        self.syncInterval = syncInterval
        self.logSync = logSync
        self.scheduleOnBackground = scheduleOnBackground
        self.scheduleOnForeground = scheduleOnForeground

        super.init()

        setup(selectedIndex)
    }

    // MARK: Private Methods

    fileprivate func setup(_ selectedIndex: Observable<Int>) {
        recurringListingsRequest()
            .takeUntil(rx.deallocated)
            .bindTo(saleArtworks)
            .addDisposableTo(rx_disposeBag)

        showSpinner = sortedSaleArtworks.asObservable().map { sortedSaleArtworks in
            sortedSaleArtworks.count == 0
        }

        gridSelected = selectedIndex.map { ListingsViewModel.SwitchValues(rawValue: $0) == .some(.grid) }

        let distinctSaleArtworks = saleArtworks
            .asObservable()
            .distinctUntilChanged { lhs, rhs -> Bool in
                lhs == rhs
            }
            .mapReplace(with: 0) // To use in combineLatest, we must have an array of identically-typed observables.

        Observable.combineLatest([selectedIndex, distinctSaleArtworks]) { ints in
            // We use distinctSaleArtworks to trigger an update, but ints[1] is unused.
            ints[0]
        }
        .startWith(0)
        .map { selectedIndex in
            ListingsViewModel.SwitchValues(rawValue: selectedIndex)
        }
        .filterNil()
        .map { [weak self] switchValue -> [SaleArtwork] in
            guard let me = self else { return [] }
            return switchValue.sortSaleArtworks(me.saleArtworks.value)
        }
        .bindTo(sortedSaleArtworks)
        .addDisposableTo(rx_disposeBag)
    }

    fileprivate func listingsRequest(forPage page: Int) -> Observable<Any> {
        provider.request(.auctionListings(id: auctionID, page: page, pageSize: pageSize)).filterSuccessfulStatusCodes().mapJSON()
    }

    // Repeatedly calls itself with page+1 until the count of the returned array is < pageSize.
    fileprivate func retrieveAllListingsRequest(_ page: Int) -> Observable<Any> {
        Observable.create { [weak self] observer in
            guard let me = self else { return Disposables.create() }

            return me.listingsRequest(forPage: page).subscribe(onNext: { object in
                guard let array = object as? [AnyObject] else { return }
                guard let me = self else { return }

                // This'll either be the next page request or .empty.
                let nextPage: Observable<Any>

                    // We must have more results to retrieve
                    = if array.count >= me.pageSize
                {
                    me.retrieveAllListingsRequest(page + 1)
                } else {
                    .empty()
                }

                // TODO: Anything with this disposable?
                _ = Observable<Any>.just(object)
                    .concat(nextPage)
                    .subscribe(observer)
            })
        }
    }

    // Fetches all pages of the auction
    fileprivate func allListingsRequest() -> Observable<[SaleArtwork]> {
        let backgroundJSONParsing = scheduleOnBackground(retrieveAllListingsRequest(1)).reduce([Any]()) { memo, object in
            guard let array = object as? [Any] else { return memo }
            return memo + array
        }
        .mapTo(arrayOf: SaleArtwork.self)
        .logServerError(message: "Sale artworks failed to retrieve+parse")
        .catchErrorJustReturn([])

        return scheduleOnForeground(backgroundJSONParsing)
    }

    fileprivate func recurringListingsRequest() -> Observable<[SaleArtwork]> {
        let recurring = Observable<Int>.interval(syncInterval, scheduler: MainScheduler.instance)
            .map { _ in Date() }
            .startWith(Date())
            .takeUntil(rx.deallocated)

        return recurring
            .doOnNext(logSync)
            .flatMap { [weak self] _ in
                self?.allListingsRequest() ?? .empty()
            }
            .map { [weak self] newSaleArtworks -> [SaleArtwork] in
                guard let me = self else { return [] }

                let currentSaleArtworks = me.saleArtworks.value

                // So we want to do here is pretty simple – if the existing and new arrays are of the same length,
                // then update the individual values in the current array and return the existing value.
                // If the array's length has changed, then we pass through the new array
                if newSaleArtworks.count == currentSaleArtworks.count {
                    if update(currentSaleArtworks, newSaleArtworks: newSaleArtworks) {
                        return currentSaleArtworks
                    }
                }

                return newSaleArtworks
            }
    }

    // MARK: Private class methods

    fileprivate class func DefaultLogging(_ date: Date) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        logger.log("Syncing on \(date)")
        #endif
    }

    fileprivate class func DefaultScheduler<T>(onBackground background: Bool) -> (_ observable: Observable<T>) -> Observable<T> {
        { observable in
            if background {
                observable.observeOn(backgroundScheduler)
            } else {
                observable.observeOn(MainScheduler.instance)
            }
        }
    }

    // MARK: Public methods

    func saleArtworkViewModel(atIndexPath indexPath: IndexPath) -> SaleArtworkViewModel {
        sortedSaleArtworks.value[indexPath.item].viewModel
    }

    func imageAspectRatioForSaleArtwork(atIndexPath indexPath: IndexPath) -> CGFloat? {
        sortedSaleArtworks.value[indexPath.item].artwork.defaultImage?.aspectRatio
    }

    func hasEstimateForSaleArtwork(atIndexPath indexPath: IndexPath) -> Bool {
        let saleArtwork = sortedSaleArtworks.value[indexPath.item]
        switch (saleArtwork.estimateCents, saleArtwork.lowEstimateCents, saleArtwork.highEstimateCents) {
        case (.some, _, _): return true
        case (_, .some, .some): return true
        default: return false
        }
    }

    func showDetailsForSaleArtwork(atIndexPath indexPath: IndexPath) {
        showDetails(sortedSaleArtworks.value[indexPath.item])
    }

    func presentModalForSaleArtwork(atIndexPath indexPath: IndexPath) {
        presentModal(sortedSaleArtworks.value[indexPath.item])
    }

    // MARK: - Switch Values

    enum SwitchValues: Int {
        case grid = 0
        case leastBids
        case mostBids
        case highestCurrentBid
        case lowestCurrentBid
        case alphabetical

        var name: String {
            switch self {
            case .grid:
                "Grid"
            case .leastBids:
                "Least Bids"
            case .mostBids:
                "Most Bids"
            case .highestCurrentBid:
                "Highest Bid"
            case .lowestCurrentBid:
                "Lowest Bid"
            case .alphabetical:
                "A–Z"
            }
        }

        func sortSaleArtworks(_ saleArtworks: [SaleArtwork]) -> [SaleArtwork] {
            switch self {
            case .grid:
                saleArtworks
            case .leastBids:
                saleArtworks.sorted(by: leastBidsSort)
            case .mostBids:
                saleArtworks.sorted(by: mostBidsSort)
            case .highestCurrentBid:
                saleArtworks.sorted(by: highestCurrentBidSort)
            case .lowestCurrentBid:
                saleArtworks.sorted(by: lowestCurrentBidSort)
            case .alphabetical:
                saleArtworks.sorted(by: alphabeticalSort)
            }
        }

        static func allSwitchValues() -> [SwitchValues] {
            [grid, leastBids, mostBids, highestCurrentBid, lowestCurrentBid, alphabetical]
        }

        static func allSwitchValueNames() -> [String] {
            allSwitchValues().map { $0.name.uppercased() }
        }
    }
}

// MARK: - Sorting Functions

protocol IntOrZeroable {
    var intOrZero: Int { get }
}

extension NSNumber: IntOrZeroable {
    var intOrZero: Int {
        self as Int
    }
}

extension Optional where Wrapped: IntOrZeroable {
    var intOrZero: Int {
        value?.intOrZero ?? 0
    }
}

func leastBidsSort(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    (lhs.bidCount.intOrZero) < (rhs.bidCount.intOrZero)
}

func mostBidsSort(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    !leastBidsSort(lhs, rhs)
}

func lowestCurrentBidSort(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    (lhs.highestBidCents.intOrZero) < (rhs.highestBidCents.intOrZero)
}

func highestCurrentBidSort(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    !lowestCurrentBidSort(lhs, rhs)
}

func alphabeticalSort(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    lhs.artwork.sortableArtistID().caseInsensitiveCompare(rhs.artwork.sortableArtistID()) == .orderedAscending
}

func sortById(_ lhs: SaleArtwork, _ rhs: SaleArtwork) -> Bool {
    lhs.id.caseInsensitiveCompare(rhs.id) == .orderedAscending
}

private func update(_ currentSaleArtworks: [SaleArtwork], newSaleArtworks: [SaleArtwork]) -> Bool {
    assert(currentSaleArtworks.count == newSaleArtworks.count, "Arrays' counts must be equal.")
    // Updating the currentSaleArtworks is easy. Both are already sorted as they came from the API (by lot #).
    // Because we assume that their length is the same, we just do a linear scan through and
    // copy values from the new to the existing.

    let saleArtworksCount = currentSaleArtworks.count

    for i in 0 ..< saleArtworksCount {
        if currentSaleArtworks[i].id == newSaleArtworks[i].id {
            currentSaleArtworks[i].updateWithValues(newSaleArtworks[i])
        } else {
            // Failure: the list was the same size but had different artworks.
            return false
        }
    }

    return true
}
