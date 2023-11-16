import Foundation

class AnnotationArgumentParser {
    func parseArguments(from annotation: String) throws -> Annotations { // TODO: change return type; Annotations != arguments
        var annotationDefinitions = annotation
            .commaSeparated()
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var namespaces = annotationDefinitions[0].components(separatedBy: ":", excludingDelimiterBetween: (open: "\"'", close: "\"'"))
        annotationDefinitions[0] = namespaces.removeLast()

        var annotations = Annotations()
        for annotation in annotationDefinitions {
            let parts = annotation
                .components(separatedBy: "=", excludingDelimiterBetween: ("", ""))
                .map { $0.trimmingCharacters(in: .whitespaces) }

            if let name = parts.first, !name.isEmpty {
                guard parts.count > 1, var value = parts.last, value.isEmpty == false else {
                    annotations.append(key: name, value: .bool(true))
                    continue
                }

                value.replaceSurroundingSingleQuotes()

                if let data = value.data(using: .utf8) {
                    let annotationValue = try JSONDecoder().decode(AnnotationValue.self, from: data)
                    annotations.append(key: name, value: annotationValue)
                }
            }
        }

        if namespaces.isEmpty {
            return annotations
        } else {
            var namespaced = Annotations()
            for namespace in namespaces.reversed() {
                namespaced[namespace] = .dictionary(annotations)
                annotations = namespaced
                namespaced = Annotations()
            }
            return annotations
        }
    }
}

private extension String {
    mutating func replaceSurroundingSingleQuotes() {
        guard hasPrefix("'") && hasSuffix("'") else {
            return
        }
        removeFirst()
        removeLast()
        self = "\"" + self + "\""
    }
}
