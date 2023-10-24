extension Optional {
    var hasValue: Bool {
        switch self {
        case .none:
            false
        case .some:
            true
        }
    }
}

extension String {
    func toUInt() -> UInt? {
        UInt(self)
    }

    func toUInt(withDefault defaultValue: UInt) -> UInt {
        UInt(self) ?? defaultValue
    }
}

// Anything that can hold a value (strings, arrays, etc)
protocol Occupiable {
    var isEmpty: Bool { get }
    var isNotEmpty: Bool { get }
}

// Give a default implementation of isNotEmpty, so conformance only requires one implementation
extension Occupiable {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

extension String: Occupiable {}

// I can't think of a way to combine these collection types. Suggestions welcome.
extension Array: Occupiable {}
extension Dictionary: Occupiable {}
extension Set: Occupiable {}

// Extend the idea of occupiability to optionals. Specifically, optionals wrapping occupiable things.
extension Optional where Wrapped: Occupiable {
    var isNilOrEmpty: Bool {
        switch self {
        case .none:
            true
        case let .some(value):
            value.isEmpty
        }
    }

    var isNotNilNotEmpty: Bool {
        !isNilOrEmpty
    }
}
