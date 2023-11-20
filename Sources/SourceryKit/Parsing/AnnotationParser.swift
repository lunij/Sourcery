
struct AnnotationParser {
    let argumentParser = AnnotationArgumentParser()

    func parse(_ content: String) -> Annotations {
        var annotations: Annotations = [:]
        for line in content.components(separatedBy: .newlines) {
            for (key, value) in parseAnnotations(from: line) {
                annotations.append(key: key, value: value)
            }
        }
        return annotations
    }

    private func parseAnnotations(from commentLine: String) -> Annotations {
        let regex = /[\t ]*(\/{2,3}|\/\*{1,2}|\*)[\t ]*sourcery:/

        guard let match = commentLine.prefixMatch(of: regex) else {
            return [:]
        }

        let lowerBound = match.range.upperBound
        let upperBound = commentLine.range(of: "*/")?.lowerBound ?? commentLine.indices.endIndex

        return try! argumentParser.parseArguments(from: String(commentLine[lowerBound ..< upperBound]))
    }
}
