import Foundation
@testable import SourceryKit

class TemplateAnnotationsParserMock: TemplateAnnotationsParsing {
    enum Call: Equatable {
        case annotationRanges
        case parseAnnotations
        case removingEmptyAnnotations
    }

    var calls: [Call] = []

    var annotationRangesReturnValue: (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<NSRange>)?
    func annotationRanges(_ annotation: String, contents: String, aggregate: Bool, forceParse: [String]) -> (annotatedRanges: AnnotatedRanges, rangesToReplace: Set<NSRange>) {
        calls.append(.annotationRanges)
        if let annotationRangesReturnValue { return annotationRangesReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
    
    var parseAnnotationsReturnValue: (contents: String, annotatedRanges: AnnotatedRanges)?
    func parseAnnotations(_ annotation: String, contents: String, aggregate: Bool, forceParse: [String]) -> (contents: String, annotatedRanges: AnnotatedRanges) {
        calls.append(.parseAnnotations)
        if let parseAnnotationsReturnValue { return parseAnnotationsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
    
    var removingEmptyAnnotationsReturnValue: String?
    func removingEmptyAnnotations(from content: String) -> String {
        calls.append(.removingEmptyAnnotations)
        if let removingEmptyAnnotationsReturnValue { return removingEmptyAnnotationsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
