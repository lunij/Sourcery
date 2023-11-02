import Foundation

typealias BlockAnnotations = [String: [(body: String, range: NSRange, indentation: String)]]

protocol BlockAnnotationParsing {
    func annotationRanges(_ annotation: String, content: String, forceParse: [String]) -> (annotations: BlockAnnotations, rangesToReplace: Set<NSRange>)
    func parseAnnotations(_ annotation: String, content: String, forceParse: [String]) -> (annotations: BlockAnnotations, content: String)
    func removingEmptyAnnotations(from content: String) -> String
}

class BlockAnnotationParser: BlockAnnotationParsing {
    func regex(annotation: String) throws -> NSRegularExpression {
        let commentPattern = NSRegularExpression.escapedPattern(for: "//")
        let regex = try NSRegularExpression(
            pattern: "(^(?:\\s*?\\n)?(\\s*)\(commentPattern)\\s*?sourcery:\(annotation):)(\\S*)\\s*?(^.*?)(^\\s*?\(commentPattern)\\s*?sourcery:end)",
            options: [.allowCommentsAndWhitespace, .anchorsMatchLines, .dotMatchesLineSeparators]
        )
        return regex
    }

    func annotationRanges(_ annotation: String, content: String, forceParse: [String]) -> (annotations: BlockAnnotations, rangesToReplace: Set<NSRange>) {
        let bridged = content.bridge()
        let regex = try? regex(annotation: annotation)

        var rangesToReplace = Set<NSRange>()
        var annotations = BlockAnnotations()

        regex?.enumerateMatches(in: content, options: [], range: bridged.entireRange) { result, _, _ in
            guard let result = result, result.numberOfRanges == 6 else {
                return
            }

            let indentationRange = result.range(at: 2)
            let nameRange = result.range(at: 3)
            let startLineRange = result.range(at: 4)
            let endLineRange = result.range(at: 5)
            let bodyRange = NSRange(
                location: startLineRange.location,
                length: endLineRange.location - startLineRange.location
            )

            let indentation = bridged.substring(with: indentationRange)
            let name = bridged.substring(with: nameRange)
            let body = bridged.substring(with: bodyRange)

            var ranges = annotations[name] ?? []
            ranges.append((body: body, range: bodyRange, indentation: indentation))
            annotations[name] = ranges

            let rangeToBeRemoved = !forceParse.contains { name.hasSuffix("." + $0) || name == $0 }
            if rangeToBeRemoved {
                rangesToReplace.insert(bodyRange)
            }
        }
        return (annotations, rangesToReplace)
    }

    func parseAnnotations(_ annotation: String, content: String, forceParse: [String]) -> (annotations: BlockAnnotations, content: String) {
        let (annotations, rangesToReplace) = annotationRanges(annotation, content: content, forceParse: forceParse)

        let strigView = StringView(content)
        var bridged = content.bridge()
        rangesToReplace
            .sorted { $0.location > $1.location }
            .forEach { bridged = bridged.replacingCharacters(in: $0, with: String(repeating: " ", count: strigView.NSRangeToByteRange($0)!.length.value)) as NSString }
        return (annotations, bridged as String)
    }

    func removingEmptyAnnotations(from content: String) -> String {
        var bridged = content.bridge()
        let regex = try? regex(annotation: "\\S*")

        var rangesToReplace: [NSRange] = []

        regex?.enumerateMatches(in: content, options: [], range: bridged.entireRange) { result, _, _ in
            guard let result = result, result.numberOfRanges == 6 else {
                return
            }

            let annotationStartRange = result.range(at: 1)
            let startLineRange = result.range(at: 4)
            let endLineRange = result.range(at: 5)
            if startLineRange.length == 0 {
                rangesToReplace.append(NSRange(
                    location: annotationStartRange.location,
                    length: NSMaxRange(endLineRange) - annotationStartRange.location
                ))
            }
        }

        rangesToReplace
            .reversed()
            .forEach { bridged = bridged.replacingCharacters(in: $0, with: "") as NSString }

        return bridged as String
    }
}
