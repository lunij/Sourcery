//
//  ByteRangeConversion.swift
//  Sourcery
//
//  Created by Evgeniy Gubin on 16.04.2021.
//  Copyright © 2021 Pixle. All rights reserved.
//

import class SourceryRuntime.BytesRange

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
