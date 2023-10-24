import RxCocoa
import RxSwift
import UIKit

public extension UIView {
    var rx_hidden: AnyObserver<Bool> {
        AnyObserver { [weak self] event in
            MainScheduler.ensureExecutingOnScheduler()

            switch event {
            case let .next(value):
                self?.isHidden = value
            case let .error(error):
                bindingErrorToInterface(error)
            case .completed:
                break
            }
        }
    }
}

extension UITextField {
    var rx_returnKey: Observable<Void> {
        rx.controlEvent(.editingDidEndOnExit).takeUntil(rx.deallocated)
    }
}
