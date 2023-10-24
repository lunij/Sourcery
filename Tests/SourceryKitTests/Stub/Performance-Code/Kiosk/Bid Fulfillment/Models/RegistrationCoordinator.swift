import RxSwift
import UIKit

enum RegistrationIndex {
    case mobileVC
    case emailVC
    case passwordVC
    case creditCardVC
    case zipCodeVC
    case confirmVC

    func toInt() -> Int {
        switch self {
        case .mobileVC: 0
        case .emailVC: 1
        case .passwordVC: 1
        case .zipCodeVC: 2
        case .creditCardVC: 3
        case .confirmVC: 4
        }
    }

    static func fromInt(_ index: Int) -> RegistrationIndex {
        switch index {
        case 0: .mobileVC
        case 1: .emailVC
        case 1: .passwordVC
        case 2: .zipCodeVC
        case 3: .creditCardVC
        default: .confirmVC
        }
    }
}

class RegistrationCoordinator: NSObject {
    let currentIndex = Variable(0)
    var storyboard: UIStoryboard!

    func viewControllerForIndex(_ index: RegistrationIndex) -> UIViewController {
        currentIndex.value = index.toInt()

        switch index {
        case .mobileVC:
            return storyboard.viewController(withID: .RegisterMobile)

        case .emailVC:
            return storyboard.viewController(withID: .RegisterEmail)

        case .passwordVC:
            return storyboard.viewController(withID: .RegisterPassword)

        case .zipCodeVC:
            return storyboard.viewController(withID: .RegisterPostalorZip)

        case .creditCardVC:
            if AppSetup.sharedState.disableCardReader {
                return storyboard.viewController(withID: .ManualCardDetailsInput)
            } else {
                return storyboard.viewController(withID: .RegisterCreditCard)
            }

        case .confirmVC:
            return storyboard.viewController(withID: .RegisterConfirm)
        }
    }

    func nextViewControllerForBidDetails(_ details: BidDetails) -> UIViewController {
        if notSet(details.newUser.phoneNumber.value) {
            return viewControllerForIndex(.mobileVC)
        }

        if notSet(details.newUser.email.value) {
            return viewControllerForIndex(.emailVC)
        }

        if notSet(details.newUser.password.value) {
            return viewControllerForIndex(.passwordVC)
        }

        if notSet(details.newUser.zipCode.value), AppSetup.sharedState.needsZipCode {
            return viewControllerForIndex(.zipCodeVC)
        }

        if notSet(details.newUser.creditCardToken.value) {
            return viewControllerForIndex(.creditCardVC)
        }

        return viewControllerForIndex(.confirmVC)
    }
}

private func notSet(_ string: String?) -> Bool {
    string?.isEmpty ?? true
}
