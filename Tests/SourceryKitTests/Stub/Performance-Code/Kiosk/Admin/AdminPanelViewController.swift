import Artsy_UILabels
import UIKit

class AdminPanelViewController: UIViewController {
    @IBOutlet var auctionIDLabel: UILabel!

    @IBAction func backTapped(_: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
        appDelegate().setHelpButtonHidden(false)
    }

    @IBAction func closeAppTapped(_: AnyObject) {
        exit(1)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        appDelegate().setHelpButtonHidden(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue == .LoadAdminWebViewController {
            let webVC = segue.destination as! AuctionWebViewController
            let auctionID = AppSetup.sharedState.auctionID
            let base = AppSetup.sharedState.useStaging ? "staging.artsy.net" : "artsy.net"

            webVC.url = URL(string: "https://\(base)/feature/\(auctionID)")!

            // TODO: Hide help button
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let state = AppSetup.sharedState

        if APIKeys.sharedKeys.stubResponses {
            auctionIDLabel.text = "STUBBING API RESPONSES\nNOT CONTACTING ARTSY API"
        } else {
            let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown"
            auctionIDLabel.text = "\(state.auctionID), Kiosk version: \(version)"
        }

        let environment = state.useStaging ? "PRODUCTION" : "STAGING"
        environmentChangeButton.setTitle("USE \(environment)", for: .normal)

        let buttonsTitle = state.showDebugButtons ? "HIDE" : "SHOW"
        showAdminButtonsButton.setTitle(buttonsTitle, for: .normal)

        let readStatus = state.disableCardReader ? "ENABLE" : "DISABLE"
        toggleCardReaderButton.setTitle(readStatus, for: .normal)
    }

    @IBOutlet var environmentChangeButton: UIButton!
    @IBAction func switchStagingProductionTapped(_: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.set(!AppSetup.sharedState.useStaging, forKey: "KioskUseStaging")

        defaults.removeObject(forKey: XAppToken.DefaultsKeys.TokenKey.rawValue)
        defaults.removeObject(forKey: XAppToken.DefaultsKeys.TokenExpiry.rawValue)

        defaults.synchronize()
        delayToMainThread(1) {
            exit(1)
        }
    }

    @IBOutlet var showAdminButtonsButton: UIButton!
    @IBAction func toggleAdminButtons(_: UIButton) {
        let defaults = UserDefaults.standard
        defaults.set(!AppSetup.sharedState.showDebugButtons, forKey: "KioskShowDebugButtons")
        defaults.synchronize()
        delayToMainThread(1) {
            exit(1)
        }
    }

    @IBOutlet var cardReaderLabel: ARSerifLabel!
    @IBOutlet var toggleCardReaderButton: SecondaryActionButton!
    @IBAction func toggleCardReaderTapped(_: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.set(!AppSetup.sharedState.disableCardReader, forKey: "KioskDisableCardReader")
        defaults.synchronize()
        delayToMainThread(1) {
            exit(1)
        }
    }
}
