import Foundation
import SourceryRuntime
import XCTest
@testable import SourceryKit

class SwiftSyntaxParserAttributeTests: XCTestCase {
    func test_parsesTypeAttributeAndModifiers() throws {
        let string = """
        /*
          docs
        */
        @objc(WAGiveRecognitionCoordinator)
        // sourcery: AutoProtocol, AutoMockable
        class GiveRecognitionCoordinator: NSObject {
        }
        """
        XCTAssertEqual(
            string.parse().first?.attributes,
            ["objc": [Attribute(name: "objc", arguments: ["0": "WAGiveRecognitionCoordinator" as NSString], description: "@objc(WAGiveRecognitionCoordinator)")]]
        )

        XCTAssertEqual(
            "class Foo { func some(param: @convention(swift) @escaping ()->()) {} }".parse().first?.methods.first?.parameters.first?.typeAttributes,
            [
                "escaping": [Attribute(name: "escaping")],
                "convention": [Attribute(name: "convention", arguments: ["0": "swift" as NSString], description: "@convention(swift)")]
            ]
        )

        XCTAssertEqual("final class Foo { }".parse().first?.modifiers, [
            Modifier(name: "final")
        ])

        XCTAssertEqual(("final class Foo { }".parse().first as? Class)?.isFinal, true)

        XCTAssertEqual("@objc class Foo {}".parse().first?.attributes, [
            "objc": [Attribute(name: "objc", arguments: [:], description: "@objc")]
        ])

        XCTAssertEqual("@objc(Bar) class Foo {}".parse().first?.attributes, [
            "objc": [Attribute(name: "objc", arguments: ["0": "Bar" as NSString], description: "@objc(Bar)")]
        ])

        XCTAssertEqual("@objcMembers class Foo {}".parse().first?.attributes, [
            "objcMembers": [Attribute(name: "objcMembers", arguments: [:], description: "@objcMembers")]
        ])

        XCTAssertEqual("public class Foo {}".parse().first?.modifiers, [
            Modifier(name: "public")
        ])
    }

    func test_parsesAttributeArgumentsWithValue() {
        XCTAssertEqual("""
        @available(*, unavailable, renamed: \"NewFoo\")
        protocol Foo {}
        """.parse().first?.attributes, [
            "available": [
                Attribute(name: "available", arguments: [
                    "0": "*" as NSString,
                    "1": "unavailable" as NSString,
                    "renamed": "NewFoo" as NSString
                ], description: "@available(*, unavailable, renamed: \"NewFoo\")")
            ]
        ])

        XCTAssertEqual("""
        @available(iOS 10.0, macOS 10.12, *)
        protocol Foo {}
        """.parse().first?.attributes, [
            "available": [
                Attribute(name: "available", arguments: [
                    "0": "iOS 10.0" as NSString,
                    "1": "macOS 10.12" as NSString,
                    "2": "*" as NSString
                ], description: "@available(iOS 10.0, macOS 10.12, *)")
            ]
        ])
    }

    func test_parsesMethodAttributesAndModifiers() {
        XCTAssertEqual("class Foo { @discardableResult\n@objc(some)\nfunc some() {} }".parse().first?.methods.first?.attributes, [
            "discardableResult": [Attribute(name: "discardableResult")],
            "objc": [Attribute(name: "objc", arguments: ["0": "some" as NSString], description: "@objc(some)")]
        ])

        XCTAssertEqual("class Foo { @nonobjc convenience required init() {} }".parse().first?.initializers.first?.attributes, [
            "nonobjc": [Attribute(name: "nonobjc")]
        ])

        let initializer = "class Foo { @nonobjc convenience required init() {} }".parse().first?.initializers.first

        XCTAssertEqual(initializer?.modifiers, [
            Modifier(name: "convenience"),
            Modifier(name: "required")
        ])

        XCTAssertEqual(initializer?.isConvenienceInitializer, true)
        XCTAssertEqual(initializer?.isRequired, true)

        XCTAssertEqual("struct Foo { mutating func some() {} }".parse().first?.methods.first?.modifiers, [
            Modifier(name: "mutating")
        ])

        XCTAssertEqual("struct Foo { mutating func some() {} }".parse().first?.methods.first?.isMutating, true)

        XCTAssertEqual("class Foo { final func some() {} }".parse().first?.methods.first?.modifiers, [
            Modifier(name: "final")
        ])

        XCTAssertEqual("class Foo { final func some() {} }".parse().first?.methods.first?.isFinal, true)

        XCTAssertEqual("@objc protocol Foo { @objc optional func some() }".parse().first?.methods.first?.modifiers, [
            Modifier(name: "optional")
        ])

        XCTAssertEqual("@objc protocol Foo { @objc optional func some() }".parse().first?.methods.first?.isOptional, true)

        XCTAssertEqual("actor Foo { nonisolated func bar() {} }".parse().first?.methods.first?.isNonisolated, true)

        XCTAssertEqual("actor Foo { func bar() {} }".parse().first?.methods.first?.isNonisolated, false)
    }

    func test_parsesMethodParameterAttributes() {
        XCTAssertEqual("class Foo { func some(param: @escaping ()->()) {} }".parse().first?.methods.first?.parameters.first?.typeAttributes, [
            "escaping": [Attribute(name: "escaping")]
        ])
    }

    func test_parsesVariableAttributesAndModifiers() {
        XCTAssertEqual("class Foo { @NSCopying @objc(objcName) var name: NSString = \"\" }".parse().first?.variables.first?.attributes, [
            "NSCopying": [Attribute(name: "NSCopying", description: "@NSCopying")],
            "objc": [Attribute(name: "objc", arguments: ["0": "objcName" as NSString], description: "@objc(objcName)")]
        ])
        XCTAssertEqual("struct Foo { mutating var some: Int }".parse().first?.variables.first?.modifiers, [Modifier(name: "mutating")])
        XCTAssertEqual("class Foo { final var some: Int }".parse().first?.variables.first?.modifiers, [Modifier(name: "final")])
        XCTAssertEqual("class Foo { final var some: Int }".parse().first?.variables.first?.isFinal, true)
        XCTAssertEqual("class Foo { lazy var name: String = \"Hello\" }".parse().first?.variables.first?.modifiers, [Modifier(name: "lazy")])
        XCTAssertEqual("class Foo { lazy var name: String = \"Hello\" }".parse().first?.variables.first?.isLazy, true)

        func assertSetterAccess(_ access: String, line: UInt = #line) {
            let variable = "public class Foo { \(access)(set) var some: Int }".parse().first?.variables.first
            XCTAssertEqual(variable?.modifiers, [Modifier(name: access, detail: "set")], line: line)
            XCTAssertEqual(variable?.writeAccess, access)
        }

        assertSetterAccess("private")
        assertSetterAccess("fileprivate")
        assertSetterAccess("internal")
        assertSetterAccess("public")
        assertSetterAccess("open")

        func assertGetterAccess(_ access: String, line: UInt = #line) {
            let variable = "public class Foo { \(access) var some: Int }".parse().first?.variables.first
            XCTAssertEqual(variable?.modifiers, [Modifier(name: access)], line: line)
            XCTAssertEqual(variable?.readAccess, access)
        }

        assertGetterAccess("private")
        assertGetterAccess("fileprivate")
        assertGetterAccess("internal")
        assertGetterAccess("public")
        assertGetterAccess("open")

    }

    func test_parsesTypeAttributes() {
        XCTAssertEqual("@nonobjc class Foo {}".parse().first?.attributes, [
            "nonobjc": [Attribute(name: "nonobjc")]
        ])
    }

    func test_parsesPropertyWrapperAttributes() {
        XCTAssertEqual("""
        class Foo {
            @UserDefaults(key: "user_name", 123)
            var name: String = "abc"
        }
        """.parse().first?.variables.first?.attributes, [
            "UserDefaults": [
                Attribute(
                    name: "UserDefaults",
                    arguments: ["key": "user_name" as NSString, "1": "123" as NSString],
                    description: "@UserDefaults(key: \"user_name\", 123)"
                )
            ]
        ])
    }
}

private extension String {
    func parse() -> [Type] {
        SwiftSyntaxParser().parse(self).types
    }
}
