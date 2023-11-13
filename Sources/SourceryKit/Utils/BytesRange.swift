import Foundation

public final class BytesRange: Diffable, Equatable, Hashable, CustomStringConvertible {

    public let offset: Int64
    public let length: Int64

    public init(offset: Int64, length: Int64) {
        self.offset = offset
        self.length = length
    }

    public convenience init(range: (offset: Int64, length: Int64)) {
        self.init(offset: range.offset, length: range.length)
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? BytesRange else {
            results.append("Incorrect type <expected: BytesRange, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "offset").trackDifference(actual: self.offset, expected: castObject.offset))
        results.append(contentsOf: DiffableResult(identifier: "length").trackDifference(actual: self.length, expected: castObject.length))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "offset = \(String(describing: offset)), "
        string += "length = \(String(describing: length))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(offset)
        hasher.combine(length)
    }

    public static func == (lhs: BytesRange, rhs: BytesRange) -> Bool {
        lhs.offset == rhs.offset && lhs.length == rhs.length
    }
}
