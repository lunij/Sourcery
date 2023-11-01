import Foundation

protocol TemplateAnnotationParsing {
    typealias AnnotatedRanges = [String: [(range: Range<Substring.Index>, indentation: String)]]
    func annotationRanges(_ annotation: String, content: String, aggregate: Bool, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<Range<Substring.Index>>)
    func parseAnnotations(_ annotation: String, content: String, aggregate: Bool, forceParse: [String]) -> (content: String, annotatedRanges: AnnotatedRanges)
    func removingEmptyAnnotations(from content: String) -> String
}

extension TemplateAnnotationParsing {
    func annotationRanges(_ annotation: String, content: String, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<Range<Substring.Index>>) {
        annotationRanges(annotation, content: content, aggregate: false, forceParse: forceParse)
    }

    func parseAnnotations(_ annotation: String, content: String, forceParse: [String]) -> (content: String, annotatedRanges: AnnotatedRanges) {
        parseAnnotations(annotation, content: content, aggregate: false, forceParse: forceParse)
    }
}

class TemplateAnnotationParser: TemplateAnnotationParsing {
    let regex = /(?<indent>[ \t]*)\/\/\s*?sourcery:\S*:(?<name>.*).*\n(?<code>[\s\S]*?)\s*?\/\/\s*?sourcery:end/

    func parseAnnotations(_ annotation: String, content: String, aggregate: Bool = false, forceParse: [String]) -> (content: String, annotatedRanges: AnnotatedRanges) {
        let (annotatedRanges, rangesToReplace) = annotationRanges(annotation, content: content, aggregate: aggregate, forceParse: forceParse)
        let ranges = rangesToReplace.sorted { $0.lowerBound > $1.lowerBound }
        var content = content
        for range in ranges {
            content = content.replacingCharacters(in: range, with: " ")
        }
        return (content, annotatedRanges)
    }

    func annotationRanges(_ annotation: String, content: String, aggregate: Bool = false, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<Range<Substring.Index>>) {
        var rangesToReplace = Set<Range<Substring.Index>>()
        var annotatedRanges = AnnotatedRanges()

        for match in content.matches(of: regex) {
            let indentation = String(match.output.indent)
            let name = String(match.output.name)
            let code = match.output.code
            let range = code.startIndex ..< code.endIndex

            if aggregate {
                var ranges = annotatedRanges[name] ?? []
                ranges.append((range: range, indentation: indentation))
                annotatedRanges[name] = ranges
            } else {
                annotatedRanges[name] = [(range: range, indentation: indentation)]
            }
            let rangeToBeRemoved = !forceParse.contains { name.hasSuffix("." + $0) || name == $0 }
            if rangeToBeRemoved {
                rangesToReplace.insert(range)
            }
        }
        return (annotatedRanges, rangesToReplace)
    }

    func removingEmptyAnnotations(from content: String) -> String {
        var rangesToReplace: [Range<Substring.Index>] = []

        for match in content.matches(of: regex) where match.output.code.isEmpty {
            rangesToReplace.append(match.range)
        }

        var content = content
        for range in rangesToReplace.reversed() {
            content = content.replacingCharacters(in: range, with: "")
        }

        return content
    }
}
