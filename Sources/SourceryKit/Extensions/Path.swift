import PathKit

extension Path {
    var generatedPath: Path {
        Path("\(lastComponentWithoutExtension).generated.swift")
    }
}
