import UIKit

class AdminLogViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = try? NSString(contentsOf: logPath(), encoding: String.Encoding.ascii.rawValue) as String
    }

    @IBOutlet var textView: UITextView!
    @IBAction func backButtonTapped(_: AnyObject) {
        _ = navigationController?.popViewController(animated: true)
    }

    func logPath() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return docs.appendingPathComponent("logger.txt")
    }

    @IBAction func scrollTapped(_: AnyObject) {
        textView.scrollRangeToVisible(NSRange(location: textView.text.count - 1, length: 1))
    }
}
