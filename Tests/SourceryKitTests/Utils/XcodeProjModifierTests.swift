import XCTest
@testable import SourceryKit

class XcodeProjModifierTests: XCTestCase {
    var sut: XcodeProjModifier!

    var xcodeProjMock: XcodeProjMock!

    override func setUp() {
        super.setUp()
        xcodeProjMock = .init()
    }

    func test_modifiesXcodeProj_whenNoTargets() throws {
        sut = .init(xcode: .stub(), xcodeProj: xcodeProjMock)

        try sut.addSourceFile(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [])
    }

    func test_modifiesXcodeProj_whenTarget() throws {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.rootGroupReturnValue = .init()
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        try sut.addSourceFile(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [
            .target("FakeTarget"),
            .rootGroup,
            .addSourceFile("fakePath")
        ])
    }

    func test_modifiesXcodeProj_whenTarget_andGroup() throws {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.rootGroupReturnValue = .init()
        xcodeProjMock.addGroupIfNeededReturnValue = .init()
        sut = .init(xcode: .stub(targets: ["FakeTarget"], group: "FakeGroup"), xcodeProj: xcodeProjMock)

        try sut.addSourceFile(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [
            .target("FakeTarget"),
            .rootGroup,
            .addGroupIfNeeded("FakeGroup", "."),
            .addSourceFile("fakePath")
        ])
    }

    func test_savesXcodeProj() throws {
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        try sut.save()

        XCTAssertEqual(xcodeProjMock.calls, [.writePBXProj("fakeProjectPath", true)])
    }

    func test_failsFindingTheTarget() throws {
        xcodeProjMock.targetReturnValue = nil
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        XCTAssertThrowsError(try sut.addSourceFile(path: "fakePath")) {
            let error = $0 as? XcodeProjModifier.Error
            XCTAssertEqual(error, .targetNotFound(name: "FakeTarget"))
        }
        XCTAssertEqual(xcodeProjMock.calls, [.target("FakeTarget")])
    }

    func test_failsFindingTheRootGroup() throws {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.rootGroupReturnValue = nil
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        XCTAssertThrowsError(try sut.addSourceFile(path: "fakePath")) {
            let error = $0 as? XcodeProjModifier.Error
            XCTAssertEqual(error, .malformedXcodeProject(context: "Root group not found."))
        }
        XCTAssertEqual(xcodeProjMock.calls, [.target("FakeTarget"), .rootGroup])
    }

    func test_failsAddingSourceFile() throws {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.rootGroupReturnValue = .init()
        xcodeProjMock.addSourceFileError = StubError()
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        XCTAssertThrowsError(try sut.addSourceFile(path: "fakePath")) {
            let error = $0 as? XcodeProjModifier.Error
            XCTAssertEqual(error, .failedToAddSourceFile(
                "fakePath",
                group: nil,
                target: "FakeTarget",
                projectPath: "fakeProjectPath",
                context: "StubError()"
            ))
        }
        XCTAssertEqual(xcodeProjMock.calls, [
            .target("FakeTarget"),
            .rootGroup,
            .addSourceFile("fakePath")
        ])
    }

    func test_failsSavingXcodeProj() throws {
        xcodeProjMock.writePBXProjError = StubError()
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        XCTAssertThrowsError(try sut.save()) {
            XCTAssertTrue($0 is StubError)
        }

        XCTAssertEqual(xcodeProjMock.calls, [.writePBXProj("fakeProjectPath", true)])
    }
}
