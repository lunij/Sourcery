import SwiftSyntax

extension Attribute {
    init(from attribute: AttributeSyntax) {
        let arguments = attribute.arguments?
            .description
            .split(separator: ",")
            .map(\.trimmed)

        self.init(name: attribute.attributeName.trimmedDescription, arguments: arguments ?? [])
    }
}

extension AttributeList {
    init(from attributeList: AttributeListSyntax?) {
        guard let attributeList else {
            self.init()
            return
        }

        self = attributeList
            .compactMap { element -> Attribute? in
                if let attribute = element.as(AttributeSyntax.self) {
                    Attribute(from: attribute)
                } else {
                    nil
                }
            }
            .reduce(AttributeList()) { list, attribute in
                var list = list
                var attributes = list[attribute.name, default: []]
                attributes.append(attribute)
                list[attribute.name] = attributes
                return list
            }
    }
}
