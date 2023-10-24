import UIKit

extension UIStoryboardSegue {}

func == (lhs: UIStoryboardSegue, rhs: SegueIdentifier) -> Bool {
    lhs.identifier == rhs.rawValue
}
