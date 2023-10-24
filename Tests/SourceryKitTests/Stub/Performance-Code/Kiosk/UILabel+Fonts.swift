import UIKit

extension UILabel {
    func makeSubstringsBold(_ text: [String]) {
        text.forEach { self.makeSubstringBold($0) }
    }

    func makeSubstringBold(_ boldText: String) {
        let attributedText = attributedText!.mutableCopy() as! NSMutableAttributedString

        let range = ((text ?? "") as NSString).range(of: boldText)
        if range.location != NSNotFound {
            attributedText.setAttributes([NSFontAttributeName: UIFont.serifSemiBoldFont(withSize: font.pointSize)], range: range)
        }

        self.attributedText = attributedText
    }

    func makeSubstringsItalic(_ text: [String]) {
        text.forEach { self.makeSubstringItalic($0) }
    }

    func makeSubstringItalic(_ italicText: String) {
        let attributedText = attributedText!.mutableCopy() as! NSMutableAttributedString

        let range = ((text ?? "") as NSString).range(of: italicText)
        if range.location != NSNotFound {
            attributedText.setAttributes([NSFontAttributeName: UIFont.serifItalicFont(withSize: font.pointSize)], range: range)
        }

        self.attributedText = attributedText
    }

    func setLineHeight(_ lineHeight: Int) {
        let displayText = text ?? ""
        let attributedString = attributedText!.mutableCopy() as! NSMutableAttributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(lineHeight)
        paragraphStyle.alignment = textAlignment
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: displayText.count))

        attributedText = attributedString
    }

    func makeTransparent() {
        isOpaque = false
        backgroundColor = .clear
    }
}
