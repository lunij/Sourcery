import Action
import Foundation
import RxSwift

class GenericFormValidationViewModel {
    let command: CocoaAction
    let disposeBag = DisposeBag()

    init(isValid: Observable<Bool>, manualInvocation: Observable<Void>, finishedSubject: PublishSubject<Void>) {
        command = CocoaAction(enabledIf: isValid) { _ in
            Observable.create { observer in

                finishedSubject.onCompleted()
                observer.onCompleted()

                return Disposables.create()
            }
        }

        manualInvocation
            .subscribe(onNext: { [weak self] _ in
                self?.command.execute()
            })
            .addDisposableTo(disposeBag)
    }
}
