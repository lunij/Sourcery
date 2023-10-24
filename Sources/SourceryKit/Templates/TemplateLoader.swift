import SourceryRuntime

protocol TemplateLoading {
    func loadTemplates(from config: Configuration, cacheDisabled: Bool, buildPath: Path?) throws -> [Template]
}

class TemplateLoader: TemplateLoading {
    private let clock: TimeMeasuring

    init(clock: TimeMeasuring = ContinuousClock()) {
        self.clock = clock
    }

    func loadTemplates(from config: Configuration, cacheDisabled: Bool, buildPath: Path?) throws -> [Template] {
        logger.info("Loading templates...")
        var templates: [Template] = []
        let elapsedTime = try clock.measure {
            templates = try config.templates.allPaths.filter(\.isTemplateFile).map {
                if $0.extension == "swifttemplate" {
                    let cachePath = cacheDisabled ? nil : Path.cachesDir(sourcePath: $0, basePath: config.cacheBasePath)
                    return try SwiftTemplate(path: $0, buildPath: buildPath, cachePath: cachePath)
                } else {
                    return try StencilTemplate(path: $0)
                }
            }
        }
        logger.info("Loaded \(templates.count) templates in \(elapsedTime)")
        return templates
    }
}
