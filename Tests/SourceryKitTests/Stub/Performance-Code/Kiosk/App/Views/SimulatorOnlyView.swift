import UIKit

class DeveloperOnlyView: UIView {
    override func awakeFromNib() {
        // Show only if we're supposed to show AND we're on staging.
        isHidden = !(AppSetup.sharedState.showDebugButtons && AppSetup.sharedState.useStaging)

        if let _ = NSClassFromString("XCTest") {
            // We are running in a test.
            isHidden = true
            alpha = 0
        }
    }
}
