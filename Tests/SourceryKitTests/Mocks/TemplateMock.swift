// Generated using Sourcery

public class TemplateMock: Template {

    public init() {}

    public var path: Path {
        get { return underlyingPath }
        set(value) { underlyingPath = value }
    }
    public var underlyingPath: Path!


    // MARK: - render

    public var renderThrowableError: Error?
    public var renderCallsCount = 0
    public var renderCalled: Bool {
        return renderCallsCount > 0
    }
    public var renderReceivedContext: TemplateContext?
    public var renderReceivedInvocations: [TemplateContext] = []
    public var renderReturnValue: String!
    public var renderClosure: ((TemplateContext) throws -> String)?

    public func render(_ context: TemplateContext) throws -> String {
        if let error = renderThrowableError {
            throw error
        }
        renderCallsCount += 1
        renderReceivedContext = context
        renderReceivedInvocations.append(context)
        if let renderClosure = renderClosure {
            return try renderClosure(context)
        } else {
            return renderReturnValue
        }
    }

}
