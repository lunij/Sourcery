import Foundation

@objcMembers public final class BytesRange: NSObject {

    public let offset: Int64
    public let length: Int64

    public init(offset: Int64, length: Int64) {
        self.offset = offset
        self.length = length
    }

    public convenience init(range: (offset: Int64, length: Int64)) {
        self.init(offset: range.offset, length: range.length)
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "offset = \(String(describing: offset)), "
        string += "length = \(String(describing: length))"
        return string
    }
}
