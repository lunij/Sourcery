import PathKit
import XCTest
@testable import SourceryKit

class PathResolverTests: XCTestCase {
    var sut: PathResolver!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_resolvesPaths_whenEmpty() {
        let paths = sut.resolve(includes: [], excludes: [])
        XCTAssertEqual(paths, [])
    }

    func test_resolvesPaths_whenIncludesOnly() {
        let paths = sut.resolve(includes: ["fake/include/path"], excludes: [])
        XCTAssertEqual(paths, ["fake/include/path"])
    }

    func test_resolvesPaths_whenNoIntersection() {
        let paths = sut.resolve(includes: ["fake/include/path"], excludes: ["fake/exclude/path"])
        XCTAssertEqual(paths, ["fake/include/path"])
    }

    func test_resolvesPaths_whenExcludeIsMatchingInclude() {
        let paths = sut.resolve(
            includes: ["fake/exclude/path", "fake/include/path"],
            excludes: ["fake/exclude/path"]
        )
        XCTAssertEqual(paths, ["fake/include/path"])
    }

    func test_resolvesPaths_whenExcludeIsChildOfInclude() {
        let paths = sut.resolve(
            includes: [Stubs.sourceDirectory, "fake/include/path"],
            excludes: [Stubs.sourceDirectory + "Foo.swift"]
        )
        XCTAssertEqual(paths, [
            Stubs.sourceDirectory + "Bar.swift",
            Stubs.sourceDirectory + "TestProject",
            "fake/include/path"
        ])
    }
}
