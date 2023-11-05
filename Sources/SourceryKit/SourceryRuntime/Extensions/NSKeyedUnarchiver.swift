import Foundation

public extension NSKeyedUnarchiver {
    static func unarchivedRootObject<DecodedObjectType>(
        ofClass cls: DecodedObjectType.Type,
        from data: Data,
        requiringSecureCoding requiresSecureCoding: Bool = false
    ) throws -> DecodedObjectType? where DecodedObjectType: NSObject, DecodedObjectType: NSCoding {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = requiresSecureCoding
        return unarchiver.decodeObject(of: cls, forKey: NSKeyedArchiveRootObjectKey)
    }
}
