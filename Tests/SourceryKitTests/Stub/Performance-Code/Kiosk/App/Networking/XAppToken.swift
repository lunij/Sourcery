import Foundation

private extension Date {
    var isInPast: Bool {
        let now = Date()
        return compare(now) == ComparisonResult.orderedAscending
    }
}

struct XAppToken {
    enum DefaultsKeys: String {
        case TokenKey
        case TokenExpiry
    }

    // MARK: - Initializers

    let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    init() {
        defaults = UserDefaults.standard
    }

    // MARK: - Properties

    var token: String? {
        get {
            let key = defaults.string(forKey: DefaultsKeys.TokenKey.rawValue)
            return key
        }
        set(newToken) {
            defaults.set(newToken, forKey: DefaultsKeys.TokenKey.rawValue)
        }
    }

    var expiry: Date? {
        get {
            defaults.object(forKey: DefaultsKeys.TokenExpiry.rawValue) as? Date
        }
        set(newExpiry) {
            defaults.set(newExpiry, forKey: DefaultsKeys.TokenExpiry.rawValue)
        }
    }

    var expired: Bool {
        if let expiry {
            return expiry.isInPast
        }
        return true
    }

    var isValid: Bool {
        if let token {
            return token.isNotEmpty && !expired
        }

        return false
    }
}
