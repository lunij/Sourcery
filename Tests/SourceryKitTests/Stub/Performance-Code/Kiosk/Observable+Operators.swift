import RxSwift

extension Observable where Element: Equatable {
    func ignore(value: Element) -> Observable<Element> {
        filter { e -> Bool in
            value != e
        }
    }
}

extension Observable {
    // OK, so the idea is that I have a Variable that exposes an Observable and I want
    // to switch to the latest without mapping.
    //
    // viewModel.flatMap { saleArtworkViewModel in return saleArtworkViewModel.lotNumber }
    //
    // Becomes...
    //
    // viewModel.flatMapTo(SaleArtworkViewModel.lotNumber)
    //
    // Still not sure if this is a good idea.

    func flatMapTo<R>(_ selector: @escaping (Element) -> () -> Observable<R>) -> Observable<R> {
        map { s -> Observable<R> in
            selector(s)()
        }.switchLatest()
    }
}

protocol OptionalType {
    associatedtype Wrapped

    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    var value: Wrapped? {
        self
    }
}

extension Observable where Element: OptionalType {
    func filterNil() -> Observable<Element.Wrapped> {
        flatMap { element -> Observable<Element.Wrapped> in
            if let value = element.value {
                .just(value)
            } else {
                .empty()
            }
        }
    }

    func filterNilKeepOptional() -> Observable<Element> {
        filter { element -> Bool in
            element.value != nil
        }
    }

    func replaceNil(with nilValue: Element.Wrapped) -> Observable<Element.Wrapped> {
        flatMap { element -> Observable<Element.Wrapped> in
            if let value = element.value {
                .just(value)
            } else {
                .just(nilValue)
            }
        }
    }
}

// TODO: Added in new RxSwift?
extension Observable {
    func doOnNext(_ closure: @escaping (Element) -> Void) -> Observable<Element> {
        self.do(onNext: { element in
            closure(element)
        })
    }

    func doOnCompleted(_ closure: @escaping () -> Void) -> Observable<Element> {
        self.do(onCompleted: {
            closure()
        })
    }

    func doOnError(_ closure: @escaping (Error) -> Void) -> Observable<Element> {
        self.do(onError: { error in
            closure(error)
        })
    }
}

private let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)

extension Observable {
    func mapReplace<T>(with value: T) -> Observable<T> {
        map { _ -> T in
            value
        }
    }

    func dispatchAsyncMainScheduler() -> Observable<E> {
        observeOn(backgroundScheduler).observeOn(MainScheduler.instance)
    }
}

protocol BooleanType {
    var boolValue: Bool { get }
}

extension Bool: BooleanType {
    var boolValue: Bool { self }
}

// Maps true to false and vice versa
extension Observable where Element: BooleanType {
    func not() -> Observable<Bool> {
        map { input in
            !input.boolValue
        }
    }
}

extension Collection where Iterator.Element: ObservableType, Iterator.Element.E: BooleanType {
    func combineLatestAnd() -> Observable<Bool> {
        Observable.combineLatest(self) { bools -> Bool in
            bools.reduce(true) { memo, element in
                memo && element.boolValue
            }
        }
    }

    func combineLatestOr() -> Observable<Bool> {
        Observable.combineLatest(self) { bools in
            bools.reduce(false) { memo, element in
                memo || element.boolValue
            }
        }
    }
}

extension ObservableType {
    func then(_ closure: @escaping () -> Observable<E>?) -> Observable<E> {
        then(closure() ?? .empty())
    }

    func then(_ closure: @autoclosure @escaping () -> Observable<E>) -> Observable<E> {
        let next = Observable.deferred {
            closure()
        }

        return ignoreElements()
            .concat(next)
    }
}

extension Observable {
    func mapToOptional() -> Observable<Element?> {
        map { Optional($0) }
    }
}

func sendDispatchCompleted(to observer: AnyObserver<some Any>) {
    DispatchQueue.main.async {
        observer.onCompleted()
    }
}
