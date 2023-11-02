import Foundation

protocol BlockAnnotationParsing {
    typealias AnnotatedRanges = [String: [(range: NSRange, indentation: String)]]
    func annotationRanges(_ annotation: String, content: String, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<NSRange>)
    func parseAnnotations(_ annotation: String, content: String, forceParse: [String]) -> (content: String, annotatedRanges: AnnotatedRanges)
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

    func parseAnnotations(_ annotation: String, content: String, forceParse: [String]) -> (content: String, annotatedRanges: AnnotatedRanges) {
        let (annotatedRanges, rangesToReplace) = annotationRanges(annotation, content: content, forceParse: forceParse)

        let strigView = StringView(content)
        var bridged = content.bridge()
        rangesToReplace
            .sorted(by: { $0.location > $1.location })
            .forEach {
                bridged = bridged.replacingCharacters(in: $0, with: String(repeating: " ", count: strigView.NSRangeToByteRange($0)!.length.value)) as NSString
        }
        return (bridged as String, annotatedRanges)
    }

    func annotationRanges(_ annotation: String, content: String, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<NSRange>) {
        let bridged = content.bridge()
        let regex = try? self.regex(annotation: annotation)

        var rangesToReplace = Set<NSRange>()
        var annotatedRanges = AnnotatedRanges()

        regex?.enumerateMatches(in: content, options: [], range: bridged.entireRange) { result, _, _ in
            guard let result = result, result.numberOfRanges == 6 else {
                return
            }

            let indentationRange = result.range(at: 2)
            let nameRange = result.range(at: 3)
            let startLineRange = result.range(at: 4)
            let endLineRange = result.range(at: 5)

            let indentation = bridged.substring(with: indentationRange)
            let name = bridged.substring(with: nameRange)
            let range = NSRange(
                location: startLineRange.location,
                length: endLineRange.location - startLineRange.location
            )

            var ranges = annotatedRanges[name] ?? []
            ranges.append((range: range, indentation: indentation))
            annotatedRanges[name] = ranges

            let rangeToBeRemoved = !forceParse.contains(where: { name.hasSuffix("." + $0) || name == $0 })
            if rangeToBeRemoved {
                rangesToReplace.insert(range)
            }
        }
        return (annotatedRanges, rangesToReplace)
    }

    func removingEmptyAnnotations(from content: String) -> String {
        var bridged = content.bridge()
        let regex = try? self.regex(annotation: "\\S*")

        var rangesToReplace = [NSRange]()

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
            .forEach {
                bridged = bridged.replacingCharacters(in: $0, with: "") as NSString
        }

        return bridged as String
    }
}
