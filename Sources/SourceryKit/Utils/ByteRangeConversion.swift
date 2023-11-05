extension ByteRange {
    init(bytesRange: BytesRange) {
        self.init(location: ByteCount(bytesRange.offset), length: ByteCount(bytesRange.length))
    }
}

extension BytesRange {
    convenience init(byteRange: ByteRange) {
        self.init(offset: Int64(byteRange.location.value), length: Int64(byteRange.length.value))
    }
}
