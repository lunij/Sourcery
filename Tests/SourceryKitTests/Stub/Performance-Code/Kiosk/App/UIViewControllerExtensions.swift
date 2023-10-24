import UIKit

extension UIViewController {
    /// Short hand syntax for loading the view controller

    func loadViewProgrammatically() {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }

    /// Short hand syntax for performing a segue with a known hardcoded identity

    func performSegue(_ identifier: SegueIdentifier) {
        performSegue(withIdentifier: identifier.rawValue, sender: self)
    }

    func fulfillmentNav() -> FulfillmentNavigationController {
        (navigationController! as! FulfillmentNavigationController)
    }

    func fulfillmentContainer() -> FulfillmentContainerViewController? {
        fulfillmentNav().parent as? FulfillmentContainerViewController
    }

    func findChildViewControllerOfType(_ klass: AnyClass) -> UIViewController? {
        for child in childViewControllers {
            if child.isKind(of: klass) {
                return child
            }
        }
        return nil
    }
}
