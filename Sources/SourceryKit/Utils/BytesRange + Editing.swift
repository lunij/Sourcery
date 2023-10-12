import class SourceryRuntime.BytesRange

extension BytesRange {
    /*
     See ByteRange.changingContent(_:)
     */
    func changingContent(_ change: ByteRange) -> BytesRange {
        let byteRange = ByteRange(bytesRange: self)
        let result = byteRange.editingContent(change)
        return BytesRange(byteRange: result)
    }
}
