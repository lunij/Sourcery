import Artsy_UILabels
import Keys
import RxSwift
import Stripe
import UIKit

class SwipeCreditCardViewController: UIViewController, RegistrationSubController {
    @IBOutlet var cardStatusLabel: ARSerifLabel!
    let finished = PublishSubject<Void>()

    @IBOutlet var spinner: Spinner!
    @IBOutlet var processingLabel: UILabel!
    @IBOutlet var illustrationImageView: UIImageView!

    @IBOutlet var titleLabel: ARSerifLabel!

    class func instantiateFromStoryboard(_ storyboard: UIStoryboard) -> SwipeCreditCardViewController {
        storyboard.viewController(withID: .RegisterCreditCard) as! SwipeCreditCardViewController
    }

    let cardName = Variable("")
    let cardLastDigits = Variable("")
    let cardToken = Variable("")

    lazy var keys = EidolonKeys()
    lazy var bidDetails: BidDetails! = self.navigationController!.fulfillmentNav().bidDetails

    lazy var appSetup = AppSetup.sharedState
    lazy var cardHandler: CardHandler = if self.appSetup.useStaging {
        .init(apiKey: keys.cardflightStagingAPIClientKey(), accountToken: keys.cardflightStagingMerchantAccountToken())
    } else {
        .init(apiKey: keys.cardflightProductionAPIClientKey(), accountToken: keys.cardflightProductionMerchantAccountToken())
    }

    fileprivate let _viewWillDisappear = PublishSubject<Void>()
    var viewWillDisappear: Observable<Void> {
        self._viewWillDisappear.asObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setInProgress(false)

        cardHandler.cardStatus
            .takeUntil(viewWillDisappear)
            .subscribe(
                onNext: { message in
                    self.cardStatusLabel.text = "Card Status: \(message)"
                    if message == "Got Card" {
                        self.setInProgress(true)
                    }

                    if message.hasPrefix("Card Flight Error") {
                        self.processingLabel.text = "ERROR PROCESSING CARD - SEE ADMIN"
                    }
                },
                onError: { _ in
                    self.cardStatusLabel.text = "Card Status: Errored"
                    self.setInProgress(false)
                    self.titleLabel.text = "Please Swipe a Valid Credit Card"
                    self.titleLabel.textColor = .artsyRedRegular()
                },
                onCompleted: {
                    self.cardStatusLabel.text = "Card Status: completed"

                    if let card = self.cardHandler.card {
                        self.cardName.value = card.name
                        self.cardLastDigits.value = card.last4

                        self.cardToken.value = card.cardToken

                        if let newUser = self.navigationController?.fulfillmentNav().bidDetails.newUser {
                            newUser.name.value = (newUser.name.value.isNilOrEmpty) ? card.name : newUser.name.value
                        }
                    }

                    self.cardHandler.end()
                    self.finished.onCompleted()
                },
                onDisposed: nil
            )
            .addDisposableTo(rx_disposeBag)

        cardHandler.startSearching()

        cardName
            .asObservable()
            .takeUntil(viewWillDisappear)
            .mapToOptional()
            .bindTo(bidDetails.newUser.creditCardName)
            .addDisposableTo(rx_disposeBag)

        cardLastDigits
            .asObservable()
            .takeUntil(viewWillDisappear)
            .mapToOptional()
            .bindTo(bidDetails.newUser.creditCardDigit)
            .addDisposableTo(rx_disposeBag)

        cardToken
            .asObservable()
            .takeUntil(viewWillDisappear)
            .mapToOptional()
            .bindTo(bidDetails.newUser.creditCardToken)
            .addDisposableTo(rx_disposeBag)

        bidDetails.newUser.swipedCreditCard = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        _viewWillDisappear.onNext()
    }

    func setInProgress(_ show: Bool) {
        illustrationImageView.alpha = show ? 0.1 : 1
        processingLabel.isHidden = !show
        spinner.isHidden = !show
    }

    // Used only for development, in private extension for testing.
    fileprivate lazy var stripeManager = StripeManager()
}

private extension SwipeCreditCardViewController {
    func applyCardWithSuccess(_ success: Bool) {
        let cardFullDigits = success ? "4242424242424242" : "4000000000000002"

        stripeManager.registerCard(digits: cardFullDigits, month: 04, year: 2018, securityCode: "123", postalCode: "10013")
            .subscribe(onNext: { [weak self] token in

                self?.cardName.value = "Kiosk Staging CC Test"
                self?.cardToken.value = token.tokenId
                self?.cardLastDigits.value = token.card.last4

                if let newUser = self?.navigationController?.fulfillmentNav().bidDetails.newUser {
                    newUser.name.value = token.card.brand.name
                }

                self?.finished.onCompleted()
            })
            .addDisposableTo(rx_disposeBag)
    }

    @IBAction func dev_creditCardOKTapped(_: AnyObject) {
        applyCardWithSuccess(true)
    }

    @IBAction func dev_creditCardFailTapped(_: AnyObject) {
        applyCardWithSuccess(false)
    }
}
