import CommonCrypto
import Foundation

public extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { pointer in
            _ = CC_SHA256(pointer.baseAddress, CC_LONG(pointer.count), &hash)
        }
        return Data(hash)
    }
}

public extension String {
    func sha256() -> String? {
        guard let data = data(using: String.Encoding.utf8) else { return nil }
        let rc = data.sha256().base64EncodedString(options: [])
        return rc
    }
}
