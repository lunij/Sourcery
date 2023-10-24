import Foundation
import Moya
import RxSwift

class APIPingManager {
    let syncInterval: TimeInterval = 2
    var letOnline: Observable<Bool>!
    var provider: Networking

    init(provider: Networking) {
        self.provider = provider

        letOnline = Observable<Int>.interval(syncInterval, scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ in
                self?.ping() ?? .empty()
            }
            .retry() // Retry because ping may fail when disconnected and error.
            .startWith(true)
    }

    private func ping() -> Observable<Bool> {
        provider.request(ArtsyAPI.ping).map(responseIsOK)
    }
}
