import Foundation
import Keys

private let minimumKeyLength = 2

// MARK: - API Keys

struct APIKeys {
    let key: String
    let secret: String

    // MARK: Shared Keys

    fileprivate enum SharedKeys {
        static var instance = APIKeys()
    }

    static var sharedKeys: APIKeys {
        get {
            SharedKeys.instance
        }

        set(newSharedKeys) {
            SharedKeys.instance = newSharedKeys
        }
    }

    // MARK: Methods

    var stubResponses: Bool {
        key.count < minimumKeyLength || secret.count < minimumKeyLength
    }

    // MARK: Initializers

    init(key: String, secret: String) {
        self.key = key
        self.secret = secret
    }

    init(keys: EidolonKeys) {
        self.init(key: keys.artsyAPIClientKey() ?? "", secret: keys.artsyAPIClientSecret() ?? "")
    }

    init() {
        let keys = EidolonKeys()
        self.init(keys: keys)
    }
}
