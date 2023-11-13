import SwiftSyntax

extension Modifier {
    init(_ node: DeclModifierSyntax) {
        name = node.name.text.trimmed
        detail = node.detail?.detail.description.trimmed
    }
}

extension [Modifier] {
    func baseModifiers(parent: Type?) -> (readAccess: AccessLevel, writeAccess: AccessLevel, isStatic: Bool, isClass: Bool) {
        var readAccess: AccessLevel = .none
        var writeAccess: AccessLevel = .none
        var isStatic = false
        var isClass = false

        forEach { modifier in
            if modifier.name == "static" {
                isStatic = true
            } else if modifier.name == "class" {
                isClass = true
            }

            guard let accessLevel = AccessLevel(modifier) else {
                return
            }

            if modifier.detail == "set" {
                writeAccess = accessLevel
            } else {
                readAccess = accessLevel
                if writeAccess == .none {
                    writeAccess = accessLevel
                }
            }
        }

        if readAccess == .none {
            readAccess = .default(for: parent)
        }
        if writeAccess == .none {
            writeAccess = readAccess
        }

        return (readAccess: readAccess, writeAccess: writeAccess, isStatic: isStatic, isClass: isClass)
    }
}
