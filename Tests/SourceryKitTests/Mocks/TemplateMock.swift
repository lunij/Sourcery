import SourceryKit

class TemplateMock: Template {
    enum Call: Equatable {
        case render // TODO: TemplateContext
    }

    var calls: [Call] = []

    var path: Path

    init(path: Path = "") {
        self.path = path
    }

    var renderError: Error?
    var renderReturnValue: String?
    func render(_: TemplateContext) throws -> String {
        calls.append(.render)
        if let renderError { throw renderError }
        if let renderReturnValue { return renderReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
