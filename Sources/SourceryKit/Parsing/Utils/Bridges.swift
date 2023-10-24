import Foundation

public extension Array {
    func bridge() -> NSArray {
        self as NSArray
    }
}

public extension CharacterSet {
    func bridge() -> NSCharacterSet {
        self as NSCharacterSet
    }
}

public extension Dictionary {
    func bridge() -> NSDictionary {
        self as NSDictionary
    }
}

public extension NSString {
    func bridge() -> String {
        self as String
    }
}

public extension String {
    func bridge() -> NSString {
        self as NSString
    }
}
