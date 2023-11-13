import XCTest
@testable import SourceryKit

class AttributeTests: XCTestCase {
    var sut: Attribute!

    override func setUp() {
        sut = Attribute(name: "available", arguments: ["macOS 14.0", "iOS 17.0", "*"])
    }

    func test_equals() {
        XCTAssertEqual(sut, sut)
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Attribute(name: "objc"))
        XCTAssertNotEqual(sut, Attribute(name: "available", arguments: ["macOS 14.0", "iOS 17.0"]))
    }

    func test_description() {
        XCTAssertEqual(sut.description, "@available(macOS 14.0, iOS 17.0, *)")
        XCTAssertEqual(
            Attribute(name: "available", arguments: ["*", "unavailable", "renamed: \"NewFoo\""]).description,
            #"@available(*, unavailable, renamed: "NewFoo")"#
        )
        XCTAssertEqual(
            Attribute(name: "available", arguments: ["iOS", "deprecated: 12", "obsoleted: 13", #"message: "This is a string""#]).description,
            #"@available(iOS, deprecated: 12, obsoleted: 13, message: "This is a string")"#
        )
    }
}
