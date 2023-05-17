import XCTest
import Foundation
@testable import SourceryLib
@testable import SourceryRuntime

class TypeTests: XCTestCase {
    var sut: Type!

    let staticVariable = Variable(name: "staticVar", typeName: TypeName(name: "Int"), isStatic: true)
    let computedVariable = Variable(name: "variable", typeName: TypeName(name: "Int"), isComputed: true)
    let storedVariable = Variable(name: "otherVariable", typeName: TypeName(name: "Int"), isComputed: false)
    let supertypeVariable = Variable(name: "supertypeVariable", typeName: TypeName(name: "Int"), isComputed: true)
    let superTypeMethod = Method(name: "doSomething()", definedInTypeName: TypeName(name: "Protocol"))
    let secondMethod = Method(name: "doSomething()", returnTypeName: TypeName(name: "Int"))
    var overrideMethod: SourceryRuntime.Method { superTypeMethod }
    var overrideVariable: Variable { supertypeVariable }
    let initializer = Method(name: "init()", definedInTypeName: TypeName(name: "Foo"))
    let parentType = Type(name: "Parent")
    var protocolType: Type!
    var superType: Type!

    override func setUp() {
        protocolType = Type(name: "Protocol", variables: [Variable(name: "supertypeVariable", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none))], methods: [superTypeMethod])

        superType = Type(name: "Supertype", variables: [supertypeVariable], methods: [superTypeMethod], inheritedTypes: ["Protocol"])
        superType.implements["Protocol"] = protocolType

        sut = Type(name: "Foo", parent: parentType, variables: [storedVariable, computedVariable, staticVariable, overrideVariable], methods: [initializer, overrideMethod, secondMethod], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)])
        sut.supertype = superType
    }

    func test_beingNotAnExtensionReportsKindAsUnknown() {
        XCTAssertEqual(sut.kind, "unknown")
    }

    func test_beingAnExtensionReportsKindAsExtension() {
        XCTAssertEqual(Type(name: "Foo", isExtension: true).kind, "extension")
    }

    func test_resolvesName() {
        XCTAssertEqual(sut.name, "Parent.Foo")
    }

    func test_hasLocalName() {
        XCTAssertEqual(sut.localName, "Foo")
    }

    func test_filtersStaticVariables() {
        XCTAssertEqual(sut.staticVariables, [staticVariable])
    }

    func test_filtersComputedVariables() {
        XCTAssertEqual(sut.computedVariables, [computedVariable, overrideVariable])
    }

    func test_filtersStoredVariables() {
        XCTAssertEqual(sut.storedVariables, [storedVariable])
    }

    func test_filtersInstanceVariables() {
        XCTAssertEqual(sut.instanceVariables, [storedVariable, computedVariable, overrideVariable])
    }

    func test_filtersInitializers() {
        XCTAssertEqual(sut.initializers, [initializer])
    }

    func test_flattensMethodsFromSupertype() {
        XCTAssertEqual(sut.allMethods, [initializer, overrideMethod, secondMethod])
    }

    func test_flattensVariablesFromSupertype() {
        XCTAssertEqual(sut.allVariables, [storedVariable, computedVariable, staticVariable, overrideVariable])
        XCTAssertEqual(superType.allVariables, [supertypeVariable])
    }

    func test_isGeneric_whenGenericType() {
        let sut = Type(name: "Foo", isGeneric: true)

        XCTAssertTrue(sut.isGeneric)
    }

    func test_isGeneric_whenNotGenericType() {
        let sut = Type(name: "Foo")

        XCTAssertFalse(sut.isGeneric)
    }

    func test_containedTypes_whenSet() {
        let type = Type(name: "Bar", isExtension: false)

        sut?.containedTypes = [type]

        XCTAssertIdentical(type.parent, sut)
    }

    func test_extend_addsVariables() {
        let extraVariable = Variable(name: "variable2", typeName: TypeName(name: "Int"))
        let type = Type(name: "Foo", isExtension: true, variables: [extraVariable])

        sut.extend(type)

        XCTAssertEqual(sut.variables, [storedVariable, computedVariable, staticVariable, overrideVariable, extraVariable])
    }

    func test_extend_doesNotAddDuplicateVariables() {
        let type = Type(name: "Foo", isExtension: true, variables: [storedVariable])

        sut.extend(type)

        XCTAssertEqual(sut.variables, [storedVariable, computedVariable, staticVariable, overrideVariable])
    }

    func test_extend_doesNotAddDuplicateVariablesWithProtocolExtension() {
        let aExtension = Type(name: "Foo", isExtension: true, variables: [Variable(name: "variable", typeName: TypeName(name: "Int"), isComputed: true)])
        let aProtocol = Protocol(name: "Foo", variables: [Variable(name: "variable", typeName: TypeName(name: "Int"))])

        aProtocol.extend(aExtension)

        XCTAssertEqual(aProtocol.variables, [Variable(name: "variable", typeName: TypeName(name: "Int"))])
    }

    func test_extend_addsMethods() {
        let extraMethod = Method(name: "foo()", definedInTypeName: TypeName(name: "Foo"))
        let type = Type(name: "Foo", isExtension: true, methods: [extraMethod])

        sut.extend(type)

        XCTAssertEqual(sut.methods, [initializer, overrideMethod, secondMethod, extraMethod])
    }

    func test_extend_doesNotAddDuplicateMethodsWithProtocolExtension() {
        let aExtension = Type(name: "Foo", isExtension: true, methods: [Method(name: "foo()", definedInTypeName: TypeName(name: "Foo"))])
        let aProtocol = Protocol(name: "Foo", methods: [Method(name: "foo()", definedInTypeName: TypeName(name: "Foo"))])

        aProtocol.extend(aExtension)

        XCTAssertEqual(aProtocol.methods, [Method(name: "foo()", definedInTypeName: TypeName(name: "Foo"))])
    }

    func test_extend_addsAnnotations() {
        let expected: [String: NSObject] = ["something": NSNumber(value: 161), "ExtraAnnotation": "ExtraValue" as NSString]
        let type = Type(name: "Foo", isExtension: true, annotations: ["ExtraAnnotation": "ExtraValue" as NSString])

        sut.extend(type)

        XCTAssertEqual(sut.annotations, expected)
    }

    func test_extend_addsInheritedTypes() {
        let type = Type(name: "Foo", isExtension: true, inheritedTypes: ["Something", "New"])

        sut.extend(type)

        XCTAssertEqual(sut.inheritedTypes, ["NSObject", "Something", "New"])
        XCTAssertEqual(sut.based, ["NSObject": "NSObject", "Something": "Something", "New": "New"])
    }

    func test_extend_addsImplementedTypes() {
        let type = Type(name: "Foo", isExtension: true)
        type.implements = ["New": Protocol(name: "New")]

        sut.extend(type)

        XCTAssertEqual(sut.implements, ["New": Protocol(name: "New")])
    }

    func test_allImports_returnsImportsAfterRemovingDuplicatesForTypeWithSuperType() {
        let superType = Type(name: "Bar")
        let superTypeImports = [Import(path: "cModule"), Import(path: "aModule")]
        superType.imports = superTypeImports
        let type = Type(name: "Foo", inheritedTypes: [superType.name])
        let typeImports = [Import(path: "aModule"), Import(path: "bModule")]
        type.imports = typeImports
        type.basedTypes[superType.name] = superType
        let expectedImports = [Import(path: "aModule"), Import(path: "bModule"), Import(path: "cModule")]

        XCTAssertEqual(type.allImports.sorted { $0.path < $1.path }, expectedImports)
    }

    func test_equals_whenSameItems() {
        XCTAssertEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable, staticVariable, overrideVariable], methods: [initializer, overrideMethod, secondMethod], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
    }

    func test_differs_whenDifferentItems() {
        XCTAssertNotEqual(sut, Type(name: "Bar", parent: parentType, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .public, isExtension: false, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: true, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: false, variables: [computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: [], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: nil, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable], methods: [initializer], inheritedTypes: ["NSObject"], annotations: [:]))
        XCTAssertNotEqual(sut, Type(name: "Foo", parent: parentType, accessLevel: .internal, isExtension: false, variables: [storedVariable, computedVariable], methods: [], inheritedTypes: ["NSObject"], annotations: ["something": NSNumber(value: 161)]))
    }
}
