/// A modifier can be something like `private`, `class`, `nonmutating`.
/// If a declaration has a modifier like `private(set)` it's name will be `private` and detail will be `set`.
public struct Modifier: Diffable, Hashable {
    /// The declaration modifier name.
    public let name: String

    /// The modifier detail, if any.
    public let detail: String?

    public init(name: String, detail: String? = nil) {
        self.name = name
        self.detail = detail
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Modifier else {
            results.append("Incorrect type <expected: Modifier, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "detail").trackDifference(actual: detail, expected: castObject.detail))
        return results
    }
}

extension Modifier: CustomStringConvertible {
    public var description: String {
        if let detail {
            "\(name)(\(detail))"
        } else {
            name
        }
    }
}
