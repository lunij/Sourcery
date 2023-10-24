import Action
import FLKAutoLayout
import Foundation
import RxSwift
import UIKit

// @IBDesignable
class KeypadContainerView: UIView {
    fileprivate var keypad: KeypadView!
    fileprivate let viewModel = KeypadViewModel()

    var stringValue: Observable<String>!
    var intValue: Observable<Int>!
    var deleteAction: CocoaAction!
    var resetAction: CocoaAction!

    override func prepareForInterfaceBuilder() {
        for subview in subviews { subview.removeFromSuperview() }

        let bundle = Bundle(for: type(of: self))
        let image = UIImage(named: "KeypadViewPreviewIB", in: bundle, compatibleWith: traitCollection)
        let imageView = UIImageView(frame: bounds)
        imageView.image = image

        addSubview(imageView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        keypad = Bundle(for: type(of: self)).loadNibNamed("KeypadView", owner: self, options: nil)?.first as? KeypadView
        keypad.leftAction = viewModel.deleteAction
        keypad.rightAction = viewModel.clearAction
        keypad.keyAction = viewModel.addDigitAction

        intValue = viewModel.intValue.asObservable()
        stringValue = viewModel.stringValue.asObservable()
        deleteAction = viewModel.deleteAction
        resetAction = viewModel.clearAction

        addSubview(keypad)

        keypad.align(to: self)
    }
}
