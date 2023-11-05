import Foundation
import PathKit

@testable import SourceryKit

private class Reference {}

enum Stubs {
    static let bundle = Bundle.module
    private static let basePath = bundle.resourcePath.flatMap { Path($0) }!
    static let sourceDirectory = basePath + Path("Source/")
    static let sourceForPerformance = basePath + Path("Performance-Code/")
    static let sourceForDryRun = basePath + Path("DryRun-Code/")
    static let resultDirectory = basePath + Path("Result/")
    static let templateDirectory = basePath + Path("Templates")
    static let errorsDirectory = basePath + Path("Errors/")
    static let configs = basePath + Path("Configs/")
}
