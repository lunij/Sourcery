import Foundation
import RxSwift
import Stripe

class StripeManager: NSObject {
    var stripeClient = STPAPIClient.shared()

    func registerCard(digits: String, month: UInt, year: UInt, securityCode: String, postalCode: String) -> Observable<STPToken> {
        let card = STPCard()
        card.number = digits
        card.expMonth = month
        card.expYear = year
        card.cvc = securityCode
        card.addressZip = postalCode

        return Observable.create { [weak self] observer in
            guard let me = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            me.stripeClient?.createToken(with: card) { token, error in
                if (token as STPToken?).hasValue {
                    observer.onNext(token!)
                    observer.onCompleted()
                } else {
                    observer.onError(error!)
                }
            }

            return Disposables.create()
        }
    }

    func stringIsCreditCard(_ cardNumber: String) -> Bool {
        STPCard.validateNumber(cardNumber)
    }
}

extension STPCardBrand {
    var name: String? {
        switch self {
        case .visa:
            "Visa"
        case .amex:
            "American Express"
        case .masterCard:
            "MasterCard"
        case .discover:
            "Discover"
        case .JCB:
            "JCB"
        case .dinersClub:
            "Diners Club"
        default:
            nil
        }
    }
}
