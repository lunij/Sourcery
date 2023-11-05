import Foundation

/// :nodoc:
@objcMembers public final class BytesRange: NSObject, SourceryModel {

    public let offset: Int64
    public let length: Int64

    public init(offset: Int64, length: Int64) {
        self.offset = offset
        self.length = length
    }

    public convenience init(range: (offset: Int64, length: Int64)) {
        self.init(offset: range.offset, length: range.length)
    }

// sourcery:inline:BytesRange.AutoCoding
public required init?(coder aDecoder: NSCoder) {
    offset = aDecoder.decodeInt64(forKey: "offset")
    length = aDecoder.decodeInt64(forKey: "length")
}

public func encode(with aCoder: NSCoder) {
    aCoder.encode(offset, forKey: "offset")
    aCoder.encode(length, forKey: "length")
}
// sourcery:end
}
