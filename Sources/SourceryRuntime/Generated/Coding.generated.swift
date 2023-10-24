// Generated using Sourcery

import Foundation

extension NSCoder {
    @nonobjc func decode(forKey: String) -> String? {
        maybeDecode(forKey: forKey) as String?
    }

    @nonobjc func decode(forKey: String) -> TypeName? {
        maybeDecode(forKey: forKey) as TypeName?
    }

    @nonobjc func decode(forKey: String) -> AccessLevel? {
        maybeDecode(forKey: forKey) as AccessLevel?
    }

    @nonobjc func decode(forKey: String) -> Bool {
        decodeBool(forKey: forKey)
    }

    @nonobjc func decode(forKey: String) -> Int {
        decodeInteger(forKey: forKey)
    }

    func decode<E>(forKey: String) -> E? {
        maybeDecode(forKey: forKey) as E?
    }

    private func maybeDecode<E>(forKey: String) -> E? {
        guard let object = decodeObject(forKey: forKey) else {
            return nil
        }
        return object as? E
    }
}

extension ArrayType: NSCoding {}

extension AssociatedType: NSCoding {}

extension AssociatedValue: NSCoding {}

extension Attribute: NSCoding {}

extension BytesRange: NSCoding {}

extension ClosureParameter: NSCoding {}

extension ClosureType: NSCoding {}

extension DictionaryType: NSCoding {}

extension EnumCase: NSCoding {}

extension FileParserResult: NSCoding {}

extension GenericRequirement: NSCoding {}

extension GenericType: NSCoding {}

extension GenericTypeParameter: NSCoding {}

extension Import: NSCoding {}

extension Method: NSCoding {}

extension MethodParameter: NSCoding {}

extension Modifier: NSCoding {}

extension Subscript: NSCoding {}

extension TupleElement: NSCoding {}

extension TupleType: NSCoding {}

extension Type: NSCoding {}

extension TypeName: NSCoding {}

extension Typealias: NSCoding {}

extension Types: NSCoding {}

extension Variable: NSCoding {}
