import SourceryRuntime

protocol TemplateLoading {
    func loadTemplates(from config: Configuration, buildPath: Path?) throws -> [Template]
}

class TemplateLoader: TemplateLoading {
    private let clock: TimeMeasuring

    init(clock: TimeMeasuring = ContinuousClock()) {
        self.clock = clock
    }

    func loadTemplates(from config: Configuration, buildPath: Path?) throws -> [Template] {
        let templatePaths = try resolveTemplatePaths(from: config)
        var templates: [Template] = []
        let elapsedTime = try clock.measure {
            templates = try templatePaths.map {
                logger.info("Loading \($0.relativeToCurrent)")
                return try StencilTemplate(path: $0)
            }
        }
        logger.info("Loaded \(templates.count) templates in \(elapsedTime)")
        return templates
    }

    private func resolveTemplatePaths(from config: Configuration) throws -> [Path] {
        try config.templates
            .flatMap { $0.isDirectory ? try $0.children() : [$0] }
            .filter(\.isTemplateFile)
    }
}
