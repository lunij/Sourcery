import Foundation

public struct BlockAnnotation: Equatable, Hashable {
    public let context: String
    public let body: String
    public let range: NSRange
    public let indentation: String

    public init(context: String, body: String, range: NSRange, indentation: String) {
        self.context = context
        self.body = body
        self.range = range
        self.indentation = indentation
    }
}
