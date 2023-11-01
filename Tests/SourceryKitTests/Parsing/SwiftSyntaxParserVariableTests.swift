import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class SwiftSyntaxParserVariableTests: XCTestCase {
    func test_infersGenericTypeInitializer() {
        func verify(_ type: String) {
            let parsedTypeName = "static let generic: \(type)".structVariable?.typeName
            XCTAssertEqual("static let generic = \(type)(value: true)".structVariable?.typeName, parsedTypeName)
        }

        verify("GenericType<Bool>")
        verify("GenericType<Optional<Int>>")
        verify("GenericType<Whatever, Int, [Float]>")

        XCTAssertEqual(
            """
            var pointPool = {
                ReusableItemPool<Point>(something: "cool")
            }()
            """.structVariable?.typeName,
            "static let generic: ReusableItemPool<Point>".structVariable?.typeName
        )
    }

    func test_infersTypesForVariablesWhenItIsEasy() {
        XCTAssertEqual("static let redirectButtonDefaultURL = URL(string: \"https://www.nytimes.com\")!".structVariable?.typeName, TypeName(name: "URL!"))
    }

    func test_reportsVariableMutability() {
        XCTAssertEqual("var name: String".structVariable?.isMutable, true)
        XCTAssertEqual("let name: String".structVariable?.isMutable, false)
        XCTAssertEqual("private(set) var name: String".structVariable?.isMutable, true)
        XCTAssertEqual("var name: String { return \"\" }".structVariable?.isMutable, false)
    }

    func test_extractsStandardProperty() {
        XCTAssertEqual("var name: String".structVariable, Variable(name: "name", typeName: TypeName(name: "String"), accessLevel: (read: .internal, write: .internal), isComputed: false))
    }

    func test_extractsWithCustomAccess() {
        XCTAssertEqual(
            "private var name: String".structVariable,
            Variable(
                name: "name",
                typeName: TypeName(name: "String"),
                accessLevel: (read: .private, write: .private),
                isComputed: false,
                modifiers: [
                    Modifier(name: "private")
                ]
            )
        )

        XCTAssertEqual(
            "private(set) var name: String".structVariable,
            Variable(
                name: "name",
                typeName: TypeName(name: "String"),
                accessLevel: (read: .internal, write: .private),
                isComputed: false,
                modifiers: [
                    Modifier(name: "private", detail: "set")
                ]
            )
        )

        XCTAssertEqual(
            "public private(set) var name: String".structVariable,
            Variable(
                name: "name",
                typeName: TypeName(name: "String"),
                accessLevel: (read: .public, write: .private),
                isComputed: false,
                modifiers: [
                    Modifier(name: "public"),
                    Modifier(name: "private", detail: "set")
                ]
            )
        )
    }

    func test_protocolVariable_mutability() {
        XCTAssertEqual("var name: String { get } ".protocolVariable?.isMutable, false)
        XCTAssertEqual("var name: String { get set }".protocolVariable?.isMutable, true)

        let internalVariable = "var name: String { get set }".protocolVariable
        XCTAssertEqual(internalVariable?.writeAccess, "internal")
        XCTAssertEqual(internalVariable?.readAccess, "internal")

        let publicVariable = "public var name: String { get set }".protocolVariable
        XCTAssertEqual(publicVariable?.writeAccess, "public")
        XCTAssertEqual(publicVariable?.readAccess, "public")
    }

    func test_protocolVariable_concurrency() {
        XCTAssertEqual("var name: String { get } ".protocolVariable?.isAsync, false)
        XCTAssertEqual("var name: String { get async }".protocolVariable?.isAsync, true)
    }

    func test_protocolVariable_throwability() {
        XCTAssertEqual("var name: String { get } ".protocolVariable?.throws, false)
        XCTAssertEqual("var name: String { get throws }".protocolVariable?.throws, true)
    }

    func test_defaultValue() {
        XCTAssertEqual("var name: String = String()".structVariable?.defaultValue, "String()")
        XCTAssertEqual("var name = Parent.Children.init()".structVariable?.defaultValue, "Parent.Children.init()")
        XCTAssertEqual("var name = [[1, 2], [1, 2]]".structVariable?.defaultValue, "[[1, 2], [1, 2]]")
        XCTAssertEqual("var name = { return 0 }()".structVariable?.defaultValue, "{ return 0 }()")
        XCTAssertEqual("var name = \t\n { return 0 }() \t\n".structVariable?.defaultValue, "{ return 0 }()")
        XCTAssertEqual("var name: Int = \t\n { return 0 }() \t\n".structVariable?.defaultValue, "{ return 0 }()")
        XCTAssertEqual("var name: String = String() { didSet { print(0) } }".structVariable?.defaultValue, "String()")
        XCTAssertEqual("var name: String = String() {\n\tdidSet { print(0) }\n}".structVariable?.defaultValue, "String()")
        XCTAssertEqual("var name: String = String()\n{\n\twillSet { print(0) }\n}".structVariable?.defaultValue, "String()")
    }

    func test_typeName_whenDefaultInitializer() {
        XCTAssertEqual("var name = String()".structVariable?.typeName, TypeName(name: "String"))
        XCTAssertEqual("var name = Parent.Children.init()".structVariable?.typeName, TypeName(name: "Parent.Children"))
        XCTAssertEqual("var name: String? = String()".structVariable?.typeName, TypeName(name: "String?"))
        XCTAssertNotEqual("var name = { return 0 }() ".structVariable?.typeName, TypeName(name: "{ return 0 }"))

        XCTAssertEqual("""
        var reducer = Reducer<WorkoutTemplate.State, WorkoutTemplate.Action, GlobalEnvironment<Programs.Environment>>.combine(
            periodizationConfiguratorReducer.optional().pullback(state: \\.periodizationConfigurator, action: /WorkoutTemplate.Action.periodizationConfigurator, environment: { $0.map { _ in Programs.Environment() } })) {
            somethingUnrealted.init()
        }
        """.structVariable?.typeName, TypeName(name: "Reducer<WorkoutTemplate.State, WorkoutTemplate.Action, GlobalEnvironment<Programs.Environment>>"))
    }

    func test_typeName_whenLiteralValue() {
        XCTAssertEqual("var name = 1".structVariable?.typeName, TypeName(name: "Int"))
        XCTAssertEqual("var name = 1.0".structVariable?.typeName, TypeName(name: "Double"))
        XCTAssertEqual("var name = \"1\"".structVariable?.typeName, TypeName(name: "String"))
        XCTAssertEqual("var name = true".structVariable?.typeName, TypeName(name: "Bool"))
        XCTAssertEqual("var name = false".structVariable?.typeName, TypeName(name: "Bool"))
        XCTAssertEqual("var name = nil".structVariable?.typeName, TypeName(name: "Optional"))
        XCTAssertEqual("var name = Optional.none".structVariable?.typeName, TypeName(name: "Optional"))
        XCTAssertEqual("var name = Optional.some(1)".structVariable?.typeName, TypeName(name: "Optional"))
        XCTAssertEqual("var name = Foo.Bar()".structVariable?.typeName, TypeName(name: "Foo.Bar"))
    }

    func test_typeName_whenArrayLiteralValue() {
        XCTAssertEqual("var name = [Int]()".structVariable?.typeName, TypeName.buildArray(of: .Int))
        XCTAssertEqual("var name = [1]".structVariable?.typeName, TypeName.buildArray(of: .Int))
        XCTAssertEqual("var name = [1, 2]".structVariable?.typeName, TypeName.buildArray(of: .Int))
        XCTAssertEqual("var name = [1, \"a\"]".structVariable?.typeName, TypeName.buildArray(of: .Any))
        XCTAssertEqual("var name = [1, nil]".structVariable?.typeName, TypeName.buildArray(of: TypeName.Int.asOptional))
        XCTAssertEqual("var name = [1, [1, 2]]".structVariable?.typeName, TypeName.buildArray(of: .Any))
        XCTAssertEqual("var name = [[1, 2], [1, 2]]".structVariable?.typeName, TypeName.buildArray(of: TypeName.buildArray(of: .Int)))
        XCTAssertEqual("var name = [Int()]".structVariable?.typeName, TypeName.buildArray(of: .Int))
    }

    func test_typeName_whenDictionaryLiteralValue() {
        XCTAssertEqual("var name = [Int: Int]()".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .Int))
        XCTAssertEqual("var name = [1: 2]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .Int))
        XCTAssertEqual("var name = [1: 2, 2: 3]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .Int))
        XCTAssertEqual("var name = [1: 1, 2: \"a\"]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .Any))
        XCTAssertEqual("var name = [1: 1, 2: nil]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: TypeName.Int.asOptional))
        XCTAssertEqual("var name = [1: 1, 2: [1, 2]]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .Any))
        XCTAssertEqual("var name = [[1: 1, 2: 2], [1: 1, 2: 2]]".structVariable?.typeName, TypeName.buildArray(of: .buildDictionary(key: .Int, value: .Int)))
        XCTAssertEqual("var name = [1: [1: 1, 2: 2], 2: [1: 1, 2: 2]]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .buildDictionary(key: .Int, value: .Int)))
        XCTAssertEqual("var name = [Int(): String()]".structVariable?.typeName, TypeName.buildDictionary(key: .Int, value: .String))
    }

    func test_typeName_whenTupleLiteralValue() {
        XCTAssertEqual("var name = (1, 2)".structVariable?.typeName, TypeName.buildTuple(TypeName.Int, TypeName.Int))
        XCTAssertEqual("var name = (1, b: \"[2,3]\", c: 1)".structVariable?.typeName, TypeName.buildTuple(.init(name: "0", typeName: .Int), .init(name: "b", typeName: .String), .init(name: "c", typeName: .Int)))
        XCTAssertEqual("var name = (_: 1, b: 2)".structVariable?.typeName, TypeName.buildTuple(.init(name: "0", typeName: .Int), .init(name: "b", typeName: .Int)))
        XCTAssertEqual("var name = ((1, 2), [\"a\": \"b\"])".structVariable?.typeName, TypeName.buildTuple(TypeName.buildTuple(TypeName.Int, TypeName.Int), TypeName.buildDictionary(key: .String, value: .String)))
        XCTAssertEqual("var name = ((1, 2), [1, 2])".structVariable?.typeName, TypeName.buildTuple(TypeName.buildTuple(TypeName.Int, TypeName.Int), TypeName.buildArray(of: .Int)))
        XCTAssertEqual("var name = ((1, 2), [\"a,b\": \"b\"])".structVariable?.typeName, TypeName.buildTuple(
            .buildTuple(.Int, .Int),
            .buildDictionary(key: .String, value: .String)
        ))
    }

    func test_parsesStandardLetProperty() {
        XCTAssertEqual("let name: String".structVariable, Variable(name: "name", typeName: TypeName(name: "String"), accessLevel: (read: .internal, write: .none), isComputed: false))
    }

    func test_parsesComputedProperty() {
        XCTAssertEqual("var name: Int { return 2 }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true))
        XCTAssertEqual("let name: Int".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: false))
        XCTAssertEqual("var name: Int".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: false))
        XCTAssertEqual("var name: Int { \nget { return 0 } \nset {} }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: true))
        XCTAssertEqual("var name: Int { \nget { return 0 } }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, isAsync: false, throws: false))
        XCTAssertEqual("var name: Int { \nget async { return 0 } }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, isAsync: true, throws: false))
        XCTAssertEqual("var name: Int { \nget throws { return 0 } }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, isAsync: false, throws: true))
        XCTAssertEqual("var name: Int { \nget async throws { return 0 } }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, isAsync: true, throws: true))
        XCTAssertEqual("var name: Int \n{ willSet { } }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: false))
        XCTAssertEqual("var name: Int { \ndidSet {} }".structVariable, Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: false))
    }

    func test_parsesGenericProperty() {
        XCTAssertEqual("let name: Observable<Int>".structVariable, Variable(
            name: "name",
            typeName: TypeName(name: "Observable<Int>", generic: .init(name: "Observable", typeParameters: [.init(typeName: TypeName(name: "Int"))])),
            accessLevel: (read: .internal, write: .none),
            isComputed: false
        ))
        XCTAssertEqual("let name: Combine.Observable<Int>".structVariable, Variable(
            name: "name",
            typeName: TypeName(name: "Combine.Observable<Int>", generic: .init(name: "Combine.Observable", typeParameters: [.init(typeName: TypeName(name: "Int"))])),
            accessLevel: (read: .internal, write: .none),
            isComputed: false
        ))
    }

    func test_annotations_parsesSingleAnnotation() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["skipEquability"] = NSNumber(value: true)

        XCTAssertEqual("""
        // sourcery: skipEquability
        var name: Int { return 2 }
        """.structVariable, expectedVariable)
    }

    func test_annotations_parsesMultipleAnnotationsOnTheSameLine() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["skipEquability"] = NSNumber(value: true)
        expectedVariable.annotations["jsonKey"] = "json_key" as NSString

        XCTAssertEqual("""
        // sourcery: skipEquability, jsonKey = \"json_key\"
        var name: Int { return 2 }
        """.structVariable, expectedVariable)
    }

    func test_annotations_parsesMultilineAnnotationsIncludingNumbers() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["skipEquability"] = NSNumber(value: true)
        expectedVariable.annotations["jsonKey"] = "json_key" as NSString
        expectedVariable.annotations["thirdProperty"] = NSNumber(value: -3)

        let variable = """
        // sourcery: skipEquability, jsonKey = \"json_key\"
        // sourcery: thirdProperty = -3
        var name: Int { return 2 }
        """.structVariable
        XCTAssertEqual(variable, expectedVariable)
    }

    func test_annotations_parsesAnnotationsInterleavedWithComments() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["isSet"] = NSNumber(value: true)
        expectedVariable.annotations["numberOfIterations"] = NSNumber(value: 2)
        expectedVariable.documentation = ["isSet is used for something useful"]

        let variable = """
        // sourcery: isSet
        /// isSet is used for something useful
        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """.structVariable(parseDocumentation: true)
        XCTAssertEqual(variable, expectedVariable)
    }

    func test_annotations_stopsParsingAnnotationsIfItEncountersNonCommentLine() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["numberOfIterations"] = NSNumber(value: 2)

        let variable = """
        // sourcery: isSet

        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """.structVariable
        XCTAssertEqual(variable, expectedVariable)
    }

    func test_annotations_separatesCommentsFromVariableName() {
        let variable = """
        @SomeWrapper
        var variable2 // some comment
        """.structVariable
        let expectedVariable = Variable(name: "variable2", typeName: TypeName(name: "UnknownTypeSoAddTypeAttributionToVariable"), accessLevel: (read: .internal, write: .internal), isComputed: false, attributes: ["SomeWrapper": [Attribute(name: "SomeWrapper", arguments: [:])]])
        XCTAssertEqual(variable, expectedVariable)
    }

    func test_annotations_parsesTrailingAnnotations() {
        let expectedVariable = Variable(name: "name", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true)
        expectedVariable.annotations["jsonKey"] = "json_key" as NSString
        expectedVariable.annotations["skipEquability"] = NSNumber(value: true)

        XCTAssertEqual("// sourcery: jsonKey = \"json_key\"\nvar name: Int { return 2 } // sourcery: skipEquability".structVariable, expectedVariable)
    }
}

private extension String {
    var structVariable: Variable? {
        structVariable(parseDocumentation: false)
    }

    func structVariable(parseDocumentation: Bool) -> Variable? {
        let wrappedCode = """
        struct Wrapper {
            \(self)
        }
        """
        let result = SwiftSyntaxParser().parse(wrappedCode, parseDocumentation: parseDocumentation)
        let variable = result.types.first?.variables.first
        variable?.definedInType = nil
        variable?.definedInTypeName = nil
        return variable
    }

    var protocolVariable: Variable? {
        let wrappedCode = """
        protocol Wrapper {
            \(self)
        }
        """
        let result = SwiftSyntaxParser().parse(wrappedCode)
        let variable = result.types.first?.variables.first
        variable?.definedInType = nil
        variable?.definedInTypeName = nil
        return variable
    }
}
