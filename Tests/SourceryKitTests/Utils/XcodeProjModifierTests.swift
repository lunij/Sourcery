import XCTest
@testable import SourceryKit

class XcodeProjModifierTests: XCTestCase {
    var sut: XcodeProjModifier!

    var xcodeProjMock: XcodeProjMock!

    override func setUp() {
        super.setUp()
        xcodeProjMock = .init()
    }

    func test_modifiesXcodeProj_whenNoTargets() {
        sut = .init(xcode: .stub(), xcodeProj: xcodeProjMock)

        sut.link(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [])
    }

    func test_modifiesXcodeProj_whenTarget() {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.createGroupIfNeededReturnValue = .init()
        sut = .init(xcode: .stub(targets: ["FakeTarget"]), xcodeProj: xcodeProjMock)

        sut.link(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [
            .target("FakeTarget"), 
            .createGroupIfNeeded(nil, "."),
            .addSourceFile("fakePath")
        ])
    }

    func test_modifiesXcodeProj_whenTarget_andGroup() {
        xcodeProjMock.targetReturnValue = .init(name: "FakeTarget")
        xcodeProjMock.createGroupIfNeededReturnValue = .init()
        sut = .init(xcode: .stub(targets: ["FakeTarget"], group: "FakeGroup"), xcodeProj: xcodeProjMock)

        sut.link(path: "fakePath")

        XCTAssertEqual(xcodeProjMock.calls, [
            .target("FakeTarget"),
            .createGroupIfNeeded("FakeGroup", "."),
            .addSourceFile("fakePath")
        ])
    }
}
