import Stencil

public protocol Annotated {
    var annotations: Annotations { get }
}

public typealias Annotations = [String: AnnotationValue]

extension Annotations {
    mutating func append(key: String, value: AnnotationValue) {
        guard let oldValue = self[key] else {
            self[key] = value
            return
        }
        if case let .array(array) = oldValue {
            if array.contains(value) { return }
            self[key] = .array(array + [value])
        } else if case var .dictionary(oldDict) = oldValue, case let .dictionary(newDict) = value {
            newDict.forEach { key, value in
                oldDict.append(key: key, value: value)
            }
            self[key] = .dictionary(oldDict)
        } else if oldValue != value {
            self[key] = .array([oldValue, value])
        }
    }
}

public indirect enum AnnotationValue: Hashable {
    case array([AnnotationValue])
    case bool(Bool)
    case dictionary([String: AnnotationValue])
    case double(Double)
    case integer(Int)
    case string(String)
}

extension AnnotationValue {
    init?(_ value: Any) {
        switch value {
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .integer(value)
        case let value as Double:
            self = .double(value)
        case let value as String:
            self = .string(value)
        default:
            return nil
        }
    }
}

extension AnnotationValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .array(array):
            array.description
        case let .bool(bool):
            bool.description
        case let .dictionary(dictionary):
            dictionary.description
        case let .double(double):
            double.description
        case let .integer(integer):
            integer.description
        case let .string(string):
            string
        }
    }
}

extension AnnotationValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnnotationValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnnotationValue].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.typeMismatch(
                AnnotationValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode AnnotationValue")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .dictionary(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .integer(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        }
    }
}

extension AnnotationValue: Comparable {
    public static func < (lhs: AnnotationValue, rhs: AnnotationValue) -> Bool {
        lhs.description < rhs.description
    }
}

extension AnnotationValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Self...) {
        self = .array(elements)
    }
}

extension AnnotationValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AnnotationValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Self)...) {
        self = .dictionary(elements.reduce(into: [String: Self]()) { $0[$1.0] = $1.1 })
    }
}

extension AnnotationValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnnotationValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension AnnotationValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AnnotationValue: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        if member == "description" {
            return description
        }
        if case let .dictionary(dictionary) = self {
            return dictionary[member]
        }
        return nil
    }
}

extension AnnotationValue: ArrayConvertible {
    func toArray<T>() throws -> [T] {
        guard case let .array(array) = self else {
            throw AnnotationValueError.mismatchingType
        }
        return array.compactMap { $0 as? T }
    }
}

extension AnnotationValue: DoubleConvertible {
    public func toDouble() throws -> Double {
        guard case let .double(int) = self else {
            throw AnnotationValueError.mismatchingType
        }
        return int
    }
}

extension AnnotationValue: IntConvertible {
    public func toInt() throws -> Int {
        guard case let .integer(int) = self else {
            throw AnnotationValueError.mismatchingType
        }
        return int
    }
}

enum AnnotationValueError: Error {
    case mismatchingType
}
