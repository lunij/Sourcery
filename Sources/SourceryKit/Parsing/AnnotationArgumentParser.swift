import Foundation

class AnnotationArgumentParser {
    func parseArguments(from annotation: String) -> Annotations { // TODO: change return type; Annotations != arguments
        var annotationDefinitions = annotation.trimmingCharacters(in: .whitespaces)
            .commaSeparated()
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var namespaces = annotationDefinitions[0].components(separatedBy: ":", excludingDelimiterBetween: (open: "\"'", close: "\"'"))
        annotationDefinitions[0] = namespaces.removeLast()

        var annotations = Annotations()
        annotationDefinitions.forEach { annotation in
            let parts = annotation
                .components(separatedBy: "=", excludingDelimiterBetween: ("", ""))
                .map { $0.trimmingCharacters(in: .whitespaces) }

            if let name = parts.first, !name.isEmpty {
                guard parts.count > 1, var value = parts.last, value.isEmpty == false else {
                    annotations.append(key: name, value: NSNumber(value: true))
                    return
                }

                if let number = Float(value) {
                    annotations.append(key: name, value: NSNumber(value: number))
                } else {
                    if (value.hasPrefix("'") && value.hasSuffix("'")) || (value.hasPrefix("\"") && value.hasSuffix("\"")) {
                        value = String(value[value.index(after: value.startIndex) ..< value.index(before: value.endIndex)])
                        value = value.trimmingCharacters(in: .whitespaces)
                    }

                    guard let data = (value as String).data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    else {
                        annotations.append(key: name, value: value as NSString)
                        return
                    }
                    if let array = json as? [Any] {
                        annotations.append(key: name, value: array as NSArray)
                    } else if let dict = json as? [String: Any] {
                        annotations.append(key: name, value: dict as NSDictionary)
                    } else {
                        annotations.append(key: name, value: value as NSString)
                    }
                }
            }
        }

        if namespaces.isEmpty {
            return annotations
        } else {
            var namespaced = Annotations()
            for namespace in namespaces.reversed() {
                namespaced[namespace] = annotations as NSObject
                annotations = namespaced
                namespaced = Annotations()
            }
            return annotations
        }
    }
}
