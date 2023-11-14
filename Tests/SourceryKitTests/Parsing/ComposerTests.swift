import Foundation
import PathKit
import XCTest
@testable import SourceryKit

final class ComposerTests: XCTestCase {
    var sut: Composer!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    private func createGivenClassHierarchyScenario() -> (fooType: Type, barType: Type, bazType: Type) {
        let types = sut.compose("""
        class Foo {
            var foo: Int
            func fooMethod() {}
        }
        class Bar: Foo {
            var bar: Int
        }
        class Baz: Bar {
            var baz: Int
            func bazMethod() {}
        }
        """).types
        return (
            types[2],
            types[0],
            types[1]
        )
    }

    func test_givenClassHierarchy_itResolvesMethodsDefinedInType() {
        let scenario = createGivenClassHierarchyScenario()
        XCTAssertEqual(scenario.fooType.allMethods.first?.definedInType, scenario.fooType)
        XCTAssertEqual(scenario.barType.allMethods.first?.definedInType, scenario.fooType)
        XCTAssertEqual(scenario.bazType.allMethods.first?.definedInType, scenario.bazType)
        XCTAssertEqual(scenario.bazType.allMethods.last?.definedInType, scenario.fooType)
    }

    func test_givenClassHierarchy_itResolvesVariablesDefinedInType() {
        let scenario = createGivenClassHierarchyScenario()
        XCTAssertEqual(scenario.fooType.allVariables.first?.definedInType, scenario.fooType)
        XCTAssertEqual(scenario.barType.allVariables[0].definedInType, scenario.barType)
        XCTAssertEqual(scenario.barType.allVariables[1].definedInType, scenario.fooType)
        XCTAssertEqual(scenario.bazType.allVariables[0].definedInType, scenario.bazType)
        XCTAssertEqual(scenario.bazType.allVariables[1].definedInType, scenario.barType)
        XCTAssertEqual(scenario.bazType.allVariables[2].definedInType, scenario.fooType)
    }

    func test_givenMethodWithReturnType_itFindsActualReturnType() {
        let types = sut.compose("""
        class Foo { func foo() -> Bar { } }
        class Bar {}
        """).types
        let method = types.last?.methods.first

        XCTAssertEqual(method?.returnType, Class(name: "Bar"))
    }

    private func assertMethods(_ types: [Type], file: StaticString = #filePath, line: UInt = #line) {
        guard let fooType = types.first(where: { $0.name == "Foo" }) else {
            return XCTFail("Expected one type named 'Foo'", file: file, line: line)
        }
        guard let foo = fooType.methods.first else {
            return XCTFail("Expected first method", file: file, line: line)
        }
        guard let fooBar = fooType.methods.last, fooBar != foo else {
            return XCTFail("Expected second method", file: file, line: line)
        }
        XCTAssertEqual(foo.name, "foo<T: Equatable>()", file: file, line: line)
        XCTAssertEqual(foo.selectorName, "foo", file: file, line: line)
        XCTAssertEqual(foo.shortName, "foo<T: Equatable>", file: file, line: line)
        XCTAssertEqual(foo.callName, "foo", file: file, line: line)
        XCTAssertEqual(foo.returnTypeName, TypeName(name: "Bar? where \nT: Equatable"), file: file, line: line)
        XCTAssertEqual(foo.unwrappedReturnTypeName, "Bar", file: file, line: line)
        XCTAssertEqual(foo.returnType, Class(name: "Bar"), file: file, line: line)
        XCTAssertEqual(foo.definedInType, types.last, file: file, line: line)
        XCTAssertEqual(foo.definedInTypeName, TypeName(name: "Foo"), file: file, line: line)

        XCTAssertEqual(fooBar.name, "fooBar<T>(bar: T)", file: file, line: line)
        XCTAssertEqual(fooBar.selectorName, "fooBar(bar:)", file: file, line: line)
        XCTAssertEqual(fooBar.shortName, "fooBar<T>", file: file, line: line)
        XCTAssertEqual(fooBar.callName, "fooBar", file: file, line: line)
        XCTAssertEqual(fooBar.returnTypeName, TypeName(name: "Void where T: Equatable"), file: file, line: line)
        XCTAssertEqual(fooBar.unwrappedReturnTypeName, "Void", file: file, line: line)
        XCTAssertEqual(fooBar.returnType, nil, file: file, line: line)
        XCTAssertEqual(fooBar.definedInType, types.last, file: file, line: line)
        XCTAssertEqual(fooBar.definedInTypeName, TypeName(name: "Foo"), file: file, line: line)
    }

    func test_genericMethod_itExtractsClassMethod() {
        let types = sut.compose("""
        class Foo {
            func foo<T: Equatable>() -> Bar?\n where \nT: Equatable {
            };  /// Asks a Duck to quack
                ///
                /// - Parameter times: How many times the Duck will quack
            func fooBar<T>(bar: T) where T: Equatable { }
        };
        class Bar {}
        """).types
        assertMethods(types)
    }

    func test_genericMethod_itExtractsProtocolMethod() {
        let types = sut.compose("""
        protocol Foo {
            func foo<T: Equatable>() -> Bar?\n where \nT: Equatable  /// Asks a Duck to quack
                ///
                /// - Parameter times: How many times the Duck will quack
            func fooBar<T>(bar: T) where T: Equatable
        };
        class Bar {}
        """).types
        assertMethods(types)
    }

    func test_initializer_itExtractsInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Function(name: "init()", selectorName: "init", returnTypeName: TypeName(name: "Foo"), isStatic: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Function(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = sut.compose("class Foo { func foo() {}; init() {} }").types.first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
        XCTAssertEqual(initializer?.returnType, fooType)
    }

    func test_initializer_itExtractsFailableInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Function(name: "init?()", selectorName: "init", returnTypeName: TypeName(name: "Foo?"), isStatic: true, isFailableInitializer: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Function(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = sut.compose("class Foo { func foo() {}; init?() {} }").types.first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
        XCTAssertEqual(initializer?.returnType, fooType)
    }

    func test_protocolInheritance_itFlattensProtocolWithDefaultImplementation() {
        let types = sut.compose("""
        protocol UrlOpening {
            func open(
                _ url: URL,
                options: [UIApplication.OpenExternalURLOptionsKey: Any],
                completionHandler completion: ((Bool) -> Void)?
            )
            func open(_ url: URL)
        }

        extension UrlOpening {
            func open(_ url: URL) {
                open(url, options: [:], completionHandler: nil)
            }

            func anotherFunction(key: String) {
            }
        }
        """).types

        XCTAssertEqual(types.count, 1)

        let childProtocol = types.last
        XCTAssertEqual(childProtocol?.name, "UrlOpening")
        XCTAssertEqual(childProtocol?.allMethods.map { $0.selectorName }, ["open(_:options:completionHandler:)", "open(_:)", "anotherFunction(key:)"])
    }

    func test_protocolInheritance_itFlattensInheritedProtocolsWithDefaultImplementation() {
        let types = sut.compose("""
        protocol RemoteUrlOpening {
            func open(_ url: URL)
        }

        protocol UrlOpening: RemoteUrlOpening {
            func open(
                _ url: URL,
                options: [UIApplication.OpenExternalURLOptionsKey: Any],
                completionHandler completion: ((Bool) -> Void)?
            )
        }

        extension UrlOpening {
            func open(_ url: URL) {
                open(url, options: [:], completionHandler: nil)
            }
        }
        """).types

        XCTAssertEqual(types.count, 2)

        let childProtocol = types.last
        XCTAssertEqual(childProtocol?.name, "UrlOpening")
        XCTAssertEqual(childProtocol?.allMethods.filter({ $0.definedInType?.isExtension == false }).map { $0.selectorName }, ["open(_:options:completionHandler:)", "open(_:)"])
    }

    private func createOverlappingProtocolInheritanceScenario() -> (
        baseProtocol: Type,
        baseClass: Type,
        extendedProtocol: Type,
        extendedClass: Type
    ) {
        let types = sut.compose("""
        protocol BaseProtocol {
            var variable: Int { get }
            func baseFunction()
        }

        class BaseClass: BaseProtocol {
            var variable: Int = 0
            func baseFunction() {}
        }

        protocol ExtendedProtocol: BaseClass {
            var extendedVariable: Int { get }
            func extendedFunction()
        }

        class ExtendedClass: BaseClass, ExtendedProtocol {
            var extendedVariable: Int = 0
            func extendedFunction() { }
        }
        """).types
        return (
            types[1],
            types[0],
            types[3],
            types[2]
        )
    }

    func test_overlappingProtocolInheritance_itFindsRightTypes() {
        let (baseProtocol, baseClass, extendedProtocol, extendedClass) = createOverlappingProtocolInheritanceScenario()
        XCTAssertEqual(baseProtocol.name, "BaseProtocol")
        XCTAssertEqual(baseClass.name, "BaseClass")
        XCTAssertEqual(extendedProtocol.name, "ExtendedProtocol")
        XCTAssertEqual(extendedClass.name, "ExtendedClass")
    }

    func test_overlappingProtocolInheritance_itHasMatchingNumberOfMethodsAndVariables() {
        let (baseProtocol, baseClass, extendedProtocol, extendedClass) = createOverlappingProtocolInheritanceScenario()
        XCTAssertEqual(baseProtocol.allMethods.count, baseProtocol.allVariables.count)
        XCTAssertEqual(baseClass.allMethods.count, baseClass.allVariables.count)
        XCTAssertEqual(extendedProtocol.allMethods.count, extendedProtocol.allVariables.count)
        XCTAssertEqual(extendedClass.allMethods.count, extendedClass.allVariables.count)
    }

    func test_extensionOfSameType_itCombinesNestedTypes() {
        let types = sut.compose("struct Foo {}  extension Foo { struct Bar { } }").types

        let innerType = Struct(name: "Bar", accessLevel: .internal, isExtension: false, variables: [])
        XCTAssertEqual(types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], containedTypes: [innerType]),
            innerType
        ])
    }

    func test_extensionOfSameType_itCombinesMethods() {
        let types = sut.compose("class Baz {}; extension Baz { func foo() {} }").types
        XCTAssertEqual(types, [
            Class(name: "Baz", methods: [
                Function(name: "foo()", selectorName: "foo", accessLevel: .internal, definedInTypeName: TypeName(name: "Baz"))
            ])
        ])
    }

    func test_extensionOfSameType_itCombinesVariables() {
        let types = sut.compose("class Baz {}; extension Baz { var foo: Int }").types
        XCTAssertEqual(types, [
            Class(name: "Baz", variables: [
                .init(name: "foo", typeName: .Int, definedInTypeName: TypeName(name: "Baz"))
            ])
        ])
    }

    func test_extensionOfSameType_itCombinesVariablesAndMethodsWithAccessInformationFromTheExtension() {
        let types = sut.compose("""
        public struct Foo { }
        public extension Foo {
          func foo() { }
          var boo: Int { 0 }
        }
        """).types

        XCTAssertEqual(
            types.last,
            Struct(
                name: "Foo",
                accessLevel: .public,
                isExtension: false,
                variables: [.init(name: "boo", typeName: .Int, accessLevel: (.public, .none), isComputed: true, definedInTypeName: TypeName(name: "Foo"))],
                methods: [.init(name: "foo()", selectorName: "foo", accessLevel: .public, definedInTypeName: TypeName(name: "Foo"))],
                modifiers: [.init(name: "public")]
            )
        )
    }

    func test_extensionOfSameType_itCombinesInheritedTypes() {
        let types = sut.compose("class Foo: TestProtocol { }; extension Foo: AnotherProtocol {}").types
        XCTAssertEqual(types, [
            Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol", "AnotherProtocol"])
        ])
    }

    func test_extensionOfSameType_itDoesNotUseExtensionToInferEnumRawType() {
        let types = sut.compose("enum Foo { case one }; extension Foo: Equatable {}").types
        XCTAssertEqual(types, [
            Enum(
                name: "Foo",
                inheritedTypes: ["Equatable"],
                cases: [EnumCase(name: "one")]
            )
        ])
    }

    private func createOriginalDefinitionTypeScenario() -> (Function, Function) {
        let method = Function(
            name: "fooMethod(bar: String)",
            selectorName: "fooMethod(bar:)",
            parameters: [
                FunctionParameter(name: "bar", typeName: TypeName(name: "String"))
            ],
            returnTypeName: TypeName(name: "Void"),
            definedInTypeName: TypeName(name: "Foo")
        )
        let defaultedMethod = Function(
            name: "fooMethod(bar: String = \"Baz\")",
            selectorName: "fooMethod(bar:)",
            parameters: [
                FunctionParameter(name: "bar", typeName: TypeName(name: "String"), defaultValue: "\"Baz\"")
            ],
            returnTypeName: TypeName(name: "Void"),
            accessLevel: .internal,
            definedInTypeName: TypeName(name: "Foo")
        )
        return (method, defaultedMethod)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andEnum_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let types = sut.compose("enum Foo { case A; func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }").types
        let originalType = Enum(name: "Foo", cases: [EnumCase(name: "A")], methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(types.first?.methods.first?.definedInType, originalType)
        XCTAssertEqual(types.first?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andProtocol_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let types = sut.compose("protocol Foo { func \(method.name) }; extension Foo { func \(defaultedMethod.name) {} }").types
        let originalType = Protocol(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(types.first?.methods.first?.definedInType, originalType)
        XCTAssertEqual(types.first?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andClass_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let types = sut.compose("class Foo { func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }").types
        let originalType = Class(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(types.first?.methods.first?.definedInType, originalType)
        XCTAssertEqual(types.first?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andStruct_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let types = sut.compose("struct Foo { func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }").types
        let originalType = Struct(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(types.first?.methods.first?.definedInType, originalType)
        XCTAssertEqual(types.first?.methods.last?.definedInType, typeExtension)
    }

    func test_enumContainingAssociatedValues_itTrimsWhitespaceFromAssociatedValueNames() {
        XCTAssertEqual(
            sut.compose("enum Foo {\n case bar(\nvalue: String,\n other: Int\n)\n}").types,
            [
                Enum(
                    name: "Foo",
                    accessLevel: .internal,
                    isExtension: false,
                    inheritedTypes: [],
                    rawTypeName: nil,
                    cases: [
                        EnumCase(
                            name: "bar",
                            rawValue: nil,
                            associatedValues: [
                                AssociatedValue(
                                    localName: "value",
                                    externalName: "value",
                                    typeName: TypeName(name: "String")
                                ),
                                AssociatedValue(
                                    localName: "other",
                                    externalName: "other",
                                    typeName: TypeName(name: "Int")
                                )
                            ],
                            annotations: [:]
                        )
                    ]
                )
            ]
        )
    }

    func test_enumContainingRawType_itExtractsEnumsWithoutRawRepresentable() {
        XCTAssertEqual(
            sut.compose("enum Foo: String, SomeProtocol { case optionA }; protocol SomeProtocol {}").types,
            [
                Enum(
                    name: "Foo",
                    accessLevel: .internal,
                    isExtension: false,
                    inheritedTypes: ["SomeProtocol"],
                    rawTypeName: TypeName(name: "String"),
                    cases: [EnumCase(name: "optionA")]
                ),
                Protocol(name: "SomeProtocol")
            ]
        )
    }

    func test_enumContainingRawType_itExtractsEnumsWithRawRepresentableByInferringFromVariable() {
        XCTAssertEqual(
            sut.compose("enum Foo: RawRepresentable { case optionA; var rawValue: String { return \"\" }; init?(rawValue: String) { self = .optionA } }").types,
            [
                Enum(
                    name: "Foo",
                    inheritedTypes: ["RawRepresentable"],
                    rawTypeName: TypeName(name: "String"),
                    cases: [EnumCase(name: "optionA")],
                    variables: [
                        Variable(
                            name: "rawValue",
                            typeName: TypeName(name: "String"),
                            accessLevel: (read: .internal, write: .none),
                            isComputed: true,
                            isStatic: false,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ],
                    methods: [
                        Function(
                            name: "init?(rawValue: String)",
                            selectorName: "init(rawValue:)",
                            parameters: [FunctionParameter(name: "rawValue",typeName: TypeName(name: "String"))],
                            returnTypeName: TypeName(name: "Foo?"),
                            isStatic: true,
                            isFailableInitializer: true,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ]
                )
            ]
        )
    }

    func test_enumContainingRawType_itExtractsEnumsWithRawRepresentableByInferringFromVariableWithTypealias() {
        XCTAssertEqual(
            sut.compose("""
            enum Foo: RawRepresentable {
                case optionA
                typealias RawValue = String
                var rawValue: RawValue { return \"\" }
                init?(rawValue: RawValue) { self = .optionA }
            }
            """).types,
            [
                Enum(
                    name: "Foo",
                    inheritedTypes: ["RawRepresentable"],
                    rawTypeName: TypeName(name: "String"),
                    cases: [EnumCase(name: "optionA")],
                    variables: [
                        Variable(
                            name: "rawValue",
                            typeName: TypeName(name: "RawValue"),
                            accessLevel: (read: .internal, write: .none),
                            isComputed: true,
                            isStatic: false,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ],
                    methods: [
                        Function(
                            name: "init?(rawValue: RawValue)",
                            selectorName: "init(rawValue:)",
                            parameters: [FunctionParameter(name: "rawValue", typeName: TypeName(name: "RawValue"))],
                            returnTypeName: TypeName(name: "Foo?"),
                            isStatic: true,
                            isFailableInitializer: true,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ],
                    typealiases: [Typealias(aliasName: "RawValue", typeName: TypeName(name: "String"))]
                )
            ]
        )
    }

    func test_enumContainingRawType_itExtractsEnumsWithRawRepresentableByInferringFromTypealias() {
        XCTAssertEqual(
            sut.compose("""
            enum Foo: CustomStringConvertible, RawRepresentable {
                case optionA
                typealias RawValue = String
                var rawValue: RawValue { return \"\" }
                init?(rawValue: RawValue) { self = .optionA }
            }
            """).types,
            [
                Enum(
                    name: "Foo",
                    inheritedTypes: ["CustomStringConvertible", "RawRepresentable"],
                    rawTypeName: TypeName(name: "String"),
                    cases: [EnumCase(name: "optionA")],
                    variables: [
                        Variable(
                            name: "rawValue",
                            typeName: TypeName(name: "RawValue"),
                            accessLevel: (read: .internal, write: .none),
                            isComputed: true,
                            isStatic: false,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ],
                    methods: [
                        Function(
                            name: "init?(rawValue: RawValue)",
                            selectorName: "init(rawValue:)",
                            parameters: [FunctionParameter(name: "rawValue", typeName: TypeName(name: "RawValue"))],
                            returnTypeName: TypeName(name: "Foo?"),
                            isStatic: true,
                            isFailableInitializer: true,
                            definedInTypeName: TypeName(name: "Foo")
                        )
                    ],
                    typealiases: [Typealias(aliasName: "RawValue", typeName: TypeName(name: "String"))]
                )
            ]
        )
    }

    func test_enumWithoutRawTypeWithInheritingType_itDoesNotSetInheritedTypeToRawValueTypeForEnumCases() {
        XCTAssertEqual(
            sut.compose("enum Enum: SomeProtocol { case optionA }").types.first { $0.name == "Enum" },
            // ATM it is expected that we assume that first inherited type is a raw value type. To avoid that client code should specify inherited type via extension
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"], rawTypeName: TypeName(name: "SomeProtocol"), cases: [EnumCase(name: "optionA")])
        )
    }

    func test_enumWithoutRawTypeWithInheritingType_itDoesNotSetInheritedTypeToRawValueTypeForEnumCasesWithAssociatedValues() {
        XCTAssertEqual(
            sut.compose("enum Enum: SomeProtocol { case optionA(Int); case optionB;  }").types.first { $0.name == "Enum" },
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"], cases: [
                EnumCase(name: "optionA", associatedValues: [AssociatedValue(typeName: TypeName(name: "Int"))]),
                EnumCase(name: "optionB")
            ])
        )
    }

    func test_enumWithoutRawTypeWithInheritingType_itDoesNotSetInheritedTypeToRawValueTypeForEnumWithNoCases() {
        XCTAssertEqual(
            sut.compose("enum Enum: SomeProtocol { }").types.first { $0.name == "Enum" },
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"])
        )
    }

    func test_enumInheritingProtocolComposition_itExtractsTheProtocolCompositionAsTheInheritedType() {
        XCTAssertEqual(
            sut.compose("enum Enum: Composition { }; typealias Composition = Foo & Bar; protocol Foo {}; protocol Bar {}").types.first { $0.name == "Enum" },
            Enum(name: "Enum", inheritedTypes: ["Composition"])
        )
    }

    func test_genericCustomType_itExtractsGenericTypeName() throws {
        let types = sut.compose("""
        struct GenericArgumentStruct<T> {
            let value: T
        }

        struct Foo {
            var value: GenericArgumentStruct<Bool>
        }
        """).types

        let foo = try XCTUnwrap(types.first { $0.name == "Foo" })
        let fooGeneric = try XCTUnwrap(foo.instanceVariables.first?.typeName.generic)

        XCTAssertTrue(types.contains { $0.name == "GenericArgumentStruct" })
        XCTAssertEqual(fooGeneric.typeParameters.count, 1)
        XCTAssertEqual(fooGeneric.typeParameters.first?.typeName.name, "Bool")
    }

    func test_tupleType_itExtractsElements() {
        let types = sut.compose("""
        struct Foo {
            var tuple: (a: Int, b: Int, String, _: Float, literal: [String: [String: Float]], generic: Dictionary<String, Dictionary<String, Float>>, closure: (Int) -> (Int) -> Int, tuple: (Int, Int))
        }
        """).types
        let variable = types.first?.variables.first
        let tuple = variable?.typeName.tuple

        let stringToFloatDictGenericLiteral = GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String")), GenericTypeParameter(typeName: TypeName(name: "Float"))])
        let stringToFloatDictLiteral = DictionaryType(name: "[String: Float]", valueTypeName: TypeName(name: "Float"), keyTypeName: TypeName(name: "String"))

        XCTAssertEqual(tuple?.elements[0], TupleElement(name: "a", typeName: TypeName(name: "Int")))
        XCTAssertEqual(tuple?.elements[1], TupleElement(name: "b", typeName: TypeName(name: "Int")))
        XCTAssertEqual(tuple?.elements[2], TupleElement(name: "2", typeName: TypeName(name: "String")))
        XCTAssertEqual(tuple?.elements[3], TupleElement(name: "3", typeName: TypeName(name: "Float")))
        XCTAssertEqual(
            tuple?.elements[4],
            TupleElement(
                name: "literal",
                typeName: TypeName(
                    name: "[String: [String: Float]]",
                    dictionary: DictionaryType(
                        name: "[String: [String: Float]]",
                        valueTypeName: TypeName(
                            name: "[String: Float]",
                            dictionary: stringToFloatDictLiteral,
                            generic: stringToFloatDictGenericLiteral
                        ),
                        keyTypeName: TypeName(name: "String")
                    ),
                    generic: GenericType(
                        name: "Dictionary",
                        typeParameters: [
                            GenericTypeParameter(typeName: TypeName(name: "String")),
                            GenericTypeParameter(typeName: TypeName(name: "[String: Float]", dictionary: stringToFloatDictLiteral, generic: stringToFloatDictGenericLiteral))
                        ]
                    )
                )
            )
        )
        XCTAssertEqual(
            tuple?.elements[5],
            TupleElement(name: "generic", typeName: .buildDictionary(key: .String, value: .buildDictionary(key: .String, value: .Float, useGenericName: true), useGenericName: true))
        )
        XCTAssertEqual(
            tuple?.elements[6],
            TupleElement(name: "closure", typeName: TypeName(name: "(Int) -> (Int) -> Int", closure: ClosureType(name: "(Int) -> (Int) -> Int", parameters: [
                ClosureParameter(typeName: TypeName(name: "Int"))
            ], returnTypeName: TypeName(name: "(Int) -> Int", closure: ClosureType(name: "(Int) -> Int", parameters: [
                ClosureParameter(typeName: TypeName(name: "Int"))
            ], returnTypeName: TypeName(name: "Int"))))))
        )
        XCTAssertEqual(
            tuple?.elements[7],
            TupleElement(name: "tuple", typeName: TypeName(name: "(Int, Int)", tuple: TupleType(name: "(Int, Int)", elements: [
                TupleElement(name: "0", typeName: TypeName(name: "Int")),
                TupleElement(name: "1", typeName: TypeName(name: "Int"))
            ])))
        )
    }

    func test_literalArrayType_itExtractsElementType() {
        let types = sut.compose("""
        struct Foo {
            var array: [Int]
            var arrayOfTuples: [(Int, Int)]
            var arrayOfArrays: [[Int]], var arrayOfClosures: [() -> ()] 
        }
        """).types
        let variables = types.first?.variables
        XCTAssertEqual(
            variables?[0].typeName.array,
            ArrayType(name: "[Int]", elementTypeName: TypeName(name: "Int"))
        )
        XCTAssertEqual(
            variables?[1].typeName.array,
            ArrayType(name: "[(Int, Int)]", elementTypeName: TypeName(name: "(Int, Int)", tuple: TupleType(name: "(Int, Int)", elements: [
                TupleElement(name: "0", typeName: TypeName(name: "Int")),
                TupleElement(name: "1", typeName: TypeName(name: "Int"))
            ])))
        )
        XCTAssertEqual(
            variables?[2].typeName.array,
            ArrayType(name: "[[Int]]", elementTypeName: TypeName(name: "[Int]", array: ArrayType(name: "[Int]", elementTypeName: TypeName(name: "Int")), generic: GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Int"))])))
        )
        XCTAssertEqual(
            variables?[3].typeName,
            TypeName.buildArray(of: .buildClosure(TypeName(name: "()")))
        )
    }

    func test_genericArrayType_itExtractsElementType() {
        let types = sut.compose("""
        struct Foo {
            var array: Array<Int>
            var arrayOfTuples: Array<(Int, Int)>
            var arrayOfArrays: Array<Array<Int>>, var arrayOfClosures: Array<() -> ()>
        }
        """).types
        let variables = types.first?.variables
        XCTAssertEqual(
            variables?[0].typeName.array,
            TypeName.buildArray(of: .Int, useGenericName: true).array
        )
        XCTAssertEqual(
            variables?[1].typeName.array,
            TypeName.buildArray(of: .buildTuple(.Int, .Int), useGenericName: true).array
        )
        XCTAssertEqual(
            variables?[2].typeName.array,
            TypeName.buildArray(of: .buildArray(of: .Int, useGenericName: true), useGenericName: true).array
        )
        XCTAssertEqual(
            variables?[3].typeName.array,
            TypeName.buildArray(of: .buildClosure(TypeName(name: "()")), useGenericName: true).array
        )
    }

    func test_genericDictionaryType_itExtractsKeyType() {
        let types = sut.compose("""
        struct Foo {
            var dictionary: Dictionary<Int, String>
            var dictionaryOfArrays: Dictionary<[Int], [String]>
            var dictonaryOfDictionaries: Dictionary<Int, [Int: String]>
            var dictionaryOfTuples: Dictionary<Int, (String, String)>
            var dictionaryOfClosures: Dictionary<Int, () -> ()>
        }
        """).types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.dictionary,
            DictionaryType(name: "Dictionary<Int, String>", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "Int"))
        )
        XCTAssertEqual(
            variables?[1].typeName.dictionary,
            DictionaryType(
                name: "Dictionary<[Int], [String]>",
                valueTypeName: TypeName(
                    name: "[String]",
                    array: ArrayType(name: "[String]", elementTypeName: TypeName(name: "String")),
                    generic: GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String"))])
                ),
                keyTypeName: TypeName(
                    name: "[Int]",
                    array: ArrayType(name: "[Int]", elementTypeName: TypeName(name: "Int")),
                    generic: GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Int"))])
                )
            )
        )
        XCTAssertEqual(
            variables?[2].typeName.dictionary,
            DictionaryType(
                name: "Dictionary<Int, [Int: String]>",
                valueTypeName: TypeName(
                    name: "[Int: String]",
                    dictionary: DictionaryType(
                        name: "[Int: String]",
                        valueTypeName: TypeName(name: "String"),
                        keyTypeName: TypeName(name: "Int")
                    ),
                    generic: GenericType(
                        name: "Dictionary",
                        typeParameters: [
                            GenericTypeParameter(typeName: TypeName(name: "Int")),
                            GenericTypeParameter(typeName: TypeName(name: "String"))
                        ]
                    )
                ),
                keyTypeName: TypeName(name: "Int")
            )
        )
        XCTAssertEqual(
            variables?[3].typeName.dictionary,
            DictionaryType(
                name: "Dictionary<Int, (String, String)>",
                valueTypeName: TypeName(
                    name: "(String, String)",
                    tuple: TupleType(
                        name: "(String, String)",
                        elements: [
                            TupleElement(name: "0", typeName: TypeName(name: "String")),
                            TupleElement(name: "1", typeName: TypeName(name: "String"))
                        ]
                    )
                ),
                keyTypeName: TypeName(name: "Int")
            )
        )
        XCTAssertEqual(
            variables?[4].typeName.dictionary,
            TypeName.buildDictionary(key: .Int, value: .buildClosure(TypeName(name: "()")), useGenericName: true).dictionary
        )
    }

    func test_genericTypesExtensions_itDetectsProtocolConformanceInExtensionOfGenericTypes() {
        let types = sut.compose("""
        protocol Bar {}
        extension Array: Bar {}
        extension Dictionary: Bar {}
        extension Set: Bar {}
        struct Foo {
            var array: Array<Int>
            var arrayLiteral: [Int]
            var dictionary: Dictionary<String, Int>
            var dictionaryLiteral: [String: Int]
            var set: Set<String>
        }
        """).types
        let bar = SourceryProtocol.init(name: "Bar")
        let variables = types[3].variables
        XCTAssertEqual(variables[0].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[1].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[2].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[3].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[4].type?.implements["Bar"], bar)
    }

    func test_literalDictionaryType_itExtractsKeyType() {
        let types = sut.compose("""
        struct Foo {
            var dictionary: [Int: String]
            var dictionaryOfArrays: [[Int]: [String]]
            var dicitonaryOfDictionaries: [Int: [Int: String]]
            var dictionaryOfTuples: [Int: (String, String)]
            var dictionaryOfClojures: [Int: () -> ()]
        }
        """).types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.dictionary,
            DictionaryType(name: "[Int: String]", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "Int"))
        )
        XCTAssertEqual(
            variables?[1].typeName.dictionary,
            DictionaryType(
                name: "[[Int]: [String]]",
                valueTypeName: TypeName(
                    name: "[String]",
                    array: ArrayType(name: "[String]", elementTypeName: TypeName(name: "String")),
                    generic: GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String"))])
                ),
                keyTypeName: TypeName(
                    name: "[Int]",
                    array: ArrayType(name: "[Int]", elementTypeName: TypeName(name: "Int")),
                    generic: GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Int"))])
                )
            )
        )
        XCTAssertEqual(
            variables?[2].typeName.dictionary,
            DictionaryType(
                name: "[Int: [Int: String]]",
                valueTypeName: TypeName(
                    name: "[Int: String]",
                    dictionary: DictionaryType(name: "[Int: String]", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "Int")),
                    generic: GenericType(
                        name: "Dictionary",
                        typeParameters: [
                            GenericTypeParameter(typeName: TypeName(name: "Int")), 
                            GenericTypeParameter(typeName: TypeName(name: "String"))
                        ]
                    )
                ),
                keyTypeName: TypeName(name: "Int")
            )
        )
        XCTAssertEqual(
            variables?[3].typeName.dictionary,
            DictionaryType(
                name: "[Int: (String, String)]",
                valueTypeName: TypeName(name: "(String, String)", tuple: TupleType(name: "(String, String)", elements: [TupleElement(name: "0", typeName: TypeName(name: "String")), TupleElement(name: "1", typeName: TypeName(name: "String"))])),
                keyTypeName: TypeName(name: "Int"))
        )
        XCTAssertEqual(
            variables?[4].typeName.dictionary,
            TypeName.buildDictionary(key: .Int, value: .buildClosure(TypeName(name: "()"))).dictionary
        )
    }

    func test_closureType_itExtractsClosureReturnType() {
        let types = sut.compose("struct Foo { var closure: () -> \n Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Int", parameters: [], returnTypeName: TypeName(name: "Int"))
        )
    }

    func test_closureType_itExtractsThrowsReturnType() {
        let types = sut.compose("struct Foo { var closure: () throws -> Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() throws -> Int", parameters: [], returnTypeName: TypeName(name: "Int"), throwsOrRethrowsKeyword: "throws")
        )
    }

    func test_closureType_itExtractsVoidReturnType() {
        let types = sut.compose("struct Foo { var closure: () -> Void }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Void", parameters: [], returnTypeName: TypeName(name: "Void"))
        )
    }

    func test_closureType_itExtractsVoidAsParanthesesReturnType() {
        let types = sut.compose("struct Foo { var closure: () -> () }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> ()", parameters: [], returnTypeName: TypeName(name: "()"))
        )
    }

    func test_closureType_itExtractsComplexClosureType() {
        let types = sut.compose("struct Foo { var closure: () -> (Int) throws -> Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(
                name: "() -> (Int) throws -> Int",
                parameters: [],
                returnTypeName: TypeName(
                    name: "(Int) throws -> Int",
                    closure: ClosureType(
                        name: "(Int) throws -> Int",
                        parameters: [ClosureParameter(typeName: TypeName(name: "Int"))],
                        returnTypeName: TypeName(name: "Int"),
                        throwsOrRethrowsKeyword: "throws"
                    )
                )
            )
        )
    }

    func test_closureType_itExtractsEmptyParameters() {
        let types = sut.compose("struct Foo { var closure: () -> Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Int", parameters: [], returnTypeName: TypeName(name: "Int"))
        )
    }

    func test_closureType_itExtractsVoidParameters() {
        let types = sut.compose("struct Foo { var closure: (Void) -> Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "(Void) -> Int", parameters: [.init(typeName: TypeName(name: "Void"))], returnTypeName: .Int)
        )
    }

    func test_closureType_itExtractsParameters() {
        let types = sut.compose("struct Foo { var closure: (Int, Int -> Int) -> Int }").types
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName,
            TypeName.buildClosure(
                .Int,
                .buildClosure(.Int, returnTypeName: .Int),
                returnTypeName: .Int
            )
        )
    }

    func test_selfInsteadOfTypeName_itReplacesVariableTypesWithActualTypes() {
        let expectedVariable = Variable(
            name: "variable",
            typeName: TypeName(name: "Self", actualTypeName: TypeName(name: "Foo")),
            accessLevel: (.internal, .none),
            isComputed: true,
            definedInTypeName: TypeName(name: "Foo")
        )

        let expectedStaticVariable = Variable(
            name: "staticVar",
            typeName: TypeName(name: "Self", actualTypeName: TypeName(name: "Foo.SubType")),
            accessLevel: (.internal, .internal),
            isStatic: true,
            defaultValue: ".init()",
            modifiers: [Modifier(name: "static")],
            definedInTypeName: TypeName(name: "Foo.SubType")
        )

        let subType = Struct(name: "SubType", variables: [expectedStaticVariable])
        let fooType = Struct(name: "Foo", variables: [expectedVariable], containedTypes: [subType])

        subType.parent = fooType

        expectedVariable.type = fooType
        expectedStaticVariable.type = subType

        let types = sut.compose("""
        struct Foo {
            var variable: Self { .init() }

            struct SubType {
                static var staticVar: Self = .init()
            }
        }
        """).types

        func assert(_ variable: Variable?, expected: Variable, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(variable, expected, file: file, line: line)
            XCTAssertEqual(variable?.actualTypeName, expected.actualTypeName, file: file, line: line)
            XCTAssertEqual(variable?.type, expected.type, file: file, line: line)
        }

        assert(types.first(where: { $0.name == "Foo" })?.instanceVariables.first, expected: expectedVariable)
        assert(types.first(where: { $0.name == "Foo.SubType" })?.staticVariables.first, expected: expectedStaticVariable)
    }

    func test_selfInsteadOfTypeName_itReplacesMethodTypesWithActualTypes() {
        let expectedMethod = Function(
            name: "myMethod()",
            selectorName: "myMethod",
            returnTypeName: TypeName(name: "Self", actualTypeName: TypeName(name: "Foo.SubType")),
            definedInTypeName: TypeName(name: "Foo.SubType")
        )
        let subType = Struct(name: "SubType", methods: [expectedMethod])
        let fooType = Struct(name: "Foo", containedTypes: [subType])

        subType.parent = fooType

        let types = sut.compose("""
        struct Foo {
            struct SubType {
                func myMethod() -> Self {
                    return self
                }
            }
        }
        """).types

        let parsedSubType = types.first { $0.name == "Foo.SubType" }
        XCTAssertEqual(parsedSubType?.methods.first, expectedMethod)
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasChainToFinalType() {
        let typealiases = sut.compose("""
        enum Bar {}
        struct Foo {}
        typealias Root = Bar
        typealias Leaf1 = Root
        typealias Leaf2 = Leaf1
        typealias Leaf3 = Leaf1
        """).typealiases

        XCTAssertEqual(typealiases.count, 4)
        typealiases.forEach {
            XCTAssertEqual($0.type?.name, "Bar")
        }
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasChainContainedInTypesToFinalType() {
        let typealiases = sut.compose("""
        enum Bar {
            typealias Root = Bar
        }

        struct Foo {
            typealias Leaf1 = Bar.Root
        }
        typealias Leaf2 = Foo.Leaf1
        typealias Leaf3 = Leaf2
        typealias Leaf4 = Bar.Root
        """).typealiases

        XCTAssertEqual(typealiases.count, 5)
        typealiases.forEach {
              XCTAssertEqual($0.type?.name, "Bar")
        }
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasContainedInOtherTypes() {
        let type = sut.compose("""
        enum Module {
            typealias Model = ModuleModel
        }

        struct ModuleModel {
            class ModelID {}

            struct Element {
                let id: ModuleModel.ModelID
                let idUsingTypealias: ModuleModel.ModelID
            }
        }
        """).types[2]

        XCTAssertEqual(type.name, "ModuleModel.Element")
        XCTAssertEqual(type.variables.count, 2)
        type.variables.forEach {
            XCTAssertEqual($0.type?.name, "ModuleModel.ModelID")
        }
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasChainContainedInDifferentModulesToFinalType() {
        // TODO: add module inference logic to typealias resolution
        let typealiases = [
            Module(name: "RootModule", content: "struct Bar {}"),
            Module(name: "LeafModule1", content: "typealias Leaf1 = RootModule.Bar"),
            Module(name: "LeafModule2", content: "typealias Leaf2 = LeafModule1.Leaf1")
        ].parse().typealiases

        XCTAssertEqual(typealiases.count, 2)
        typealiases.forEach {
            XCTAssertEqual($0.type?.name, "Bar")
        }
    }

    func test_typealiases_andUpdatedComposer_itGathersFullTypeInformationIfATypeIsDefinedOnAnTypealiasedUnknownParentViaExtension() {
        let result = sut.compose("""
        typealias UnknownTypeAlias = Unknown
        extension UnknownTypeAlias {
            struct KnownStruct {
                var name: Int = 0
                var meh: Float = 0
            }
        }
        """).types
        let knownType = result.first { $0.localName == "KnownStruct" }

        XCTAssertEqual(knownType?.isExtension, false)
        XCTAssertEqual(knownType?.variables.count, 2)
    }

    func test_typealiases_andUpdatedComposer_itExtendsTheActualTypeWhenUsingTypealias() {
        let result = sut.compose("""
        struct Foo {
        }
        typealias FooAlias = Foo
        extension FooAlias {
            var name: Int { 0 }
        }
        """).types

        XCTAssertEqual(result.first?.variables.first?.typeName, TypeName.Int)
    }

    func test_typealiases_andUpdatedComposer_itResolvesInheritanceChainViaTypealias() {
        let result = sut.compose("""
        class Foo {
            class Inner {
                var innerBase: Bool
            }
            typealias Hidden = Inner
            class InnerInherited: Hidden {
                var innerInherited: Bool = true
            }
        }
        """).types
        let innerInherited = result.first { $0.localName == "InnerInherited" }

        XCTAssertEqual(innerInherited?.inheritedTypes, ["Foo.Inner"])
    }

    func test_typealiases_itResolvesDefinedInTypeForMethods() {
        let type = sut.compose("""
        class Foo { func bar() {} }
        typealias FooAlias = Foo
        extension FooAlias { func baz() {} }
        """).types.first

        XCTAssertEqual(type?.methods.first?.actualDefinedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.methods.first?.definedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.methods.first?.definedInType?.name, "Foo")
        XCTAssertEqual(type?.methods.first?.definedInType?.isExtension, false)
        XCTAssertEqual(type?.methods.last?.actualDefinedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.methods.last?.definedInTypeName, TypeName(name: "FooAlias"))
        XCTAssertEqual(type?.methods.last?.definedInType?.name, "Foo")
        XCTAssertEqual(type?.methods.last?.definedInType?.isExtension, true)
    }

    func test_typealiases_itResolvesDefinedInTypeForVariables() {
        let type = sut.compose("""
        class Foo { var bar: Int { return 1 } }
        typealias FooAlias = Foo
        extension FooAlias { var baz: Int { return 2 } }
        """).types.first

        XCTAssertEqual(type?.variables.first?.actualDefinedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.variables.first?.definedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.variables.first?.definedInType?.name, "Foo")
        XCTAssertEqual(type?.variables.first?.definedInType?.isExtension, false)
        XCTAssertEqual(type?.variables.last?.actualDefinedInTypeName, TypeName(name: "Foo"))
        XCTAssertEqual(type?.variables.last?.definedInTypeName, TypeName(name: "FooAlias"))
        XCTAssertEqual(type?.variables.last?.definedInType?.name, "Foo")
        XCTAssertEqual(type?.variables.last?.definedInType?.isExtension, true)
    }

    func test_typealiases_itSetsTypealiasType() {
        let types = sut.compose("class Bar {}; class Foo { typealias BarAlias = Bar }").types
        let bar = types.first
        let foo = types.last

        XCTAssertEqual(foo?.typealiases["BarAlias"]?.type, bar)
    }

    func test_typealiases_andVariable_itReplacesVariableAliasTypeWithActualType() {
        let expectedVariable = Variable(
            name: "foo",
            typeName: TypeName(name: "GlobalAlias", actualTypeName: TypeName(name: "Foo")),
            definedInTypeName: TypeName(name: "Bar")
        )
        expectedVariable.type = Class(name: "Foo")

        let type = sut.compose("""
        typealias GlobalAlias = Foo
        class Foo {}
        class Bar { var foo: GlobalAlias }
        """).types.first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_typealiases_andVariable_itReplacesTupleElementsAliasTypesWithActualTypes() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Type(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
            ])
        let expectedVariable = Variable(
            name: "foo",
            typeName: TypeName(
                name: "(GlobalAlias, Int)",
                actualTypeName: expectedActualTypeName,
                tuple: expectedActualTypeName.tuple
            ),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = sut.compose("""
        typealias GlobalAlias = Foo
        class Foo {}
        class Bar { var foo: (GlobalAlias, Int) }
        """).types
        let variable = types.first?.variables.first
        let tupleElement = variable?.typeName.tuple?.elements.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(tupleElement?.type, Class(name: "Foo"))
    }

    func test_typealiases_andVariable_itReplacesVariableAliasTypeWithActualTupleTypeName() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedVariable = Variable(
            name: "foo",
            typeName: TypeName(name: "GlobalAlias", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple),
            definedInTypeName: TypeName(name: "Bar")
        )

        let type = sut.compose("""
        typealias GlobalAlias = (Foo, Int)
        class Foo {}
        class Bar { var foo: GlobalAlias }
        """).types.first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.typeName.isTuple, true)
    }

    func test_typealiases_andMethodReturnType_itReplacesMethodReturnTypeAliasWithActualType() {
        let expectedMethod = Function(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = sut.compose("typealias FooAlias = Foo; class Foo {}; class Bar { func some() -> FooAlias }").types
        let method = types.first?.methods.first

        XCTAssertEqual(method, expectedMethod)
        XCTAssertEqual(method?.actualReturnTypeName, expectedMethod.actualReturnTypeName)
        XCTAssertEqual(method?.returnType, Class(name: "Foo"))
    }

    func test_typealiases_andMethodReturnType_itReplacesTupleElementsAliasTypesWithActualTypes() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedMethod = Function(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "(FooAlias, Int)", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = sut.compose("typealias FooAlias = Foo; class Foo {}; class Bar { func some() -> (FooAlias, Int) }").types
        let method = types.first?.methods.first
        let tupleElement = method?.returnTypeName.tuple?.elements.first

        XCTAssertEqual(method, expectedMethod)
        XCTAssertEqual(method?.actualReturnTypeName, expectedMethod.actualReturnTypeName)
        XCTAssertEqual(tupleElement?.type, Class(name: "Foo"))
    }

    func test_typealiases_andMethodReturnType_itReplacesMethodReturnTypeAliasWithActualTupleTypeName() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedMethod = Function(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "GlobalAlias", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = sut.compose("typealias GlobalAlias = (Foo, Int); class Foo {}; class Bar { func some() -> GlobalAlias }").types
        let method = types.first?.methods.first

        XCTAssertEqual(method, expectedMethod)
        XCTAssertEqual(method?.actualReturnTypeName, expectedMethod.actualReturnTypeName)
        XCTAssertEqual(method?.returnTypeName.isTuple, true)
    }

    func test_typealiases_andFunctionParameter_itReplacesFunctionParameterTypeAliasWithActualType() {
        let expectedFunctionParameter = FunctionParameter(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"))

        let types = sut.compose("""
        typealias FooAlias = Foo
        class Foo {}
        class Bar { func some(foo: FooAlias) }
        """).types
        let functionParameter = types.first?.methods.first?.parameters.first

        XCTAssertEqual(functionParameter, expectedFunctionParameter)
        XCTAssertEqual(functionParameter?.actualTypeName, expectedFunctionParameter.actualTypeName)
        XCTAssertEqual(functionParameter?.type, Class(name: "Foo"))
    }

    func test_typealiases_andFunctionParameter_itReplacesTupleElementsAliasTypesWithActualTypes() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedFunctionParameter = FunctionParameter(
            name: "foo",
            typeName: TypeName(name: "(FooAlias, Int)", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple)
        )

        let types = sut.compose("""
        typealias FooAlias = Foo
        class Foo {}
        class Bar { func some(foo: (FooAlias, Int)) }
        """).types
        let functionParameter = types.first?.methods.first?.parameters.first
        let tupleElement = functionParameter?.typeName.tuple?.elements.first

        XCTAssertEqual(functionParameter, expectedFunctionParameter)
        XCTAssertEqual(functionParameter?.actualTypeName, expectedFunctionParameter.actualTypeName)
        XCTAssertEqual(tupleElement?.type, Class(name: "Foo"))
    }

    func test_typealiases_andFunctionParameter_itReplacesFunctionParameterAliasTypeWithActualTupleTypeName() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedFunctionParameter = FunctionParameter(
            name: "foo",
            typeName: TypeName(name: "GlobalAlias", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple)
        )

        let types = sut.compose("typealias GlobalAlias = (Foo, Int); class Foo {}; class Bar { func some(foo: GlobalAlias) }").types
        let functionParameter = types.first?.methods.first?.parameters.first

        XCTAssertEqual(functionParameter, expectedFunctionParameter)
        XCTAssertEqual(functionParameter?.actualTypeName, expectedFunctionParameter.actualTypeName)
        XCTAssertEqual(functionParameter?.typeName.isTuple, true)
    }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueTypeAliasWithActualType() {
        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"))

        let types = sut.compose("""
        typealias FooAlias = Foo
        class Foo {}
        enum Some { case optionA(FooAlias) }
        """).types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
        XCTAssertEqual(associatedValue?.type, Class(name: "Foo"))
    }

    func test_typealias_andAssociatedValue_itReplacesTupleElementsAliasTypesWithActualType() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
            ])
        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "(FooAlias, Int)", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple))

        let types = sut.compose("typealias FooAlias = Foo; class Foo {}; enum Some { case optionA((FooAlias, Int)) }").types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first
        let tupleElement = associatedValue?.typeName.tuple?.elements.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
        XCTAssertEqual(tupleElement?.type, Class(name: "Foo"))
                        }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueAliasTypeWithActualTupleTypeName() {
        let expectedTypeName = TypeName(name: "(Foo, Int)")
        expectedTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
            ])
        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "GlobalAlias", actualTypeName: expectedTypeName, tuple: expectedTypeName.tuple))

        let types = sut.compose("typealias GlobalAlias = (Foo, Int); class Foo {}; enum Some { case optionA(GlobalAlias) }").types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
        XCTAssertEqual(associatedValue?.typeName.isTuple, true)
    }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueAliasTypeWithActualDictionaryTypeName() {
        let expectedTypeName = TypeName(name: "[String: Any]")
        expectedTypeName.dictionary = DictionaryType(name: "[String: Any]", valueTypeName: TypeName(name: "Any"), valueType: nil, keyTypeName: TypeName(name: "String"), keyType: nil)
        expectedTypeName.generic = GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String"), type: nil), GenericTypeParameter(typeName: TypeName(name: "Any"), type: nil)])

        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "JSON", actualTypeName: expectedTypeName, dictionary: expectedTypeName.dictionary, generic: expectedTypeName.generic), type: nil)

        let types = sut.compose("typealias JSON = [String: Any]; enum Some { case optionA(JSON) }").types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue?.typeName, expectedAssociatedValue.typeName)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
                        }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueAliasTypeWithActualArrayTypeName() {
        let expectedTypeName = TypeName(name: "[Any]")
        expectedTypeName.array = ArrayType(name: "[Any]", elementTypeName: TypeName(name: "Any"), elementType: nil)
        expectedTypeName.generic = GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Any"), type: nil)])

        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "JSON", actualTypeName: expectedTypeName, array: expectedTypeName.array, generic: expectedTypeName.generic), type: nil)

        let types = sut.compose("typealias JSON = [Any]; enum Some { case optionA(JSON) }").types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
                        }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueAliasTypeWithActualClosureTypeName() {
        let expectedTypeName = TypeName(name: "(String) -> Any")
        expectedTypeName.closure = ClosureType(
            name: "(String) -> Any", 
            parameters: [ClosureParameter(typeName: TypeName(name: "String"))],
            returnTypeName: TypeName(name: "Any")
        )

        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "JSON", actualTypeName: expectedTypeName, closure: expectedTypeName.closure), type: nil)

        let types = sut.compose("typealias JSON = (String) -> Any; enum Some { case optionA(JSON) }").types
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
    }

    func test_typealias_andVariable_itReplacesVariableAliasWithActualTypeViaThreeTypealiases() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FinalAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"), definedInTypeName: TypeName(name: "Bar"))

        let type = sut.compose("""
        typealias FooAlias = Foo
        typealias BarAlias = FooAlias
        typealias FinalAlias = BarAlias
        class Foo {}
        class Bar { var foo: FinalAlias }
        """).types.first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_typealias_andVariable_itReplacesVariableOptionalAliasTypeWithActualType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "GlobalAlias?", actualTypeName: TypeName(name: "Foo?")), type: Class(name: "Foo"), definedInTypeName: TypeName(name: "Bar"))

        let type = sut.compose("typealias GlobalAlias = Foo; class Foo {}; class Bar { var foo: GlobalAlias? }").types.first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_typealias_andVariable_itExtendsActualTypeWithTypeAliasExtension() {
        XCTAssertEqual(
            sut.compose("""
            typealias GlobalAlias = Foo
            class Foo: TestProtocol { }
            extension GlobalAlias: AnotherProtocol {}
            """).types,
            [
                Class(
                    name: "Foo",
                    accessLevel: .internal,
                    isExtension: false,
                    variables: [],
                    inheritedTypes: ["TestProtocol", "AnotherProtocol"]
                )
            ]
        )
    }

    func test_typealias_andVariable_itUpdatesInheritedTypesWithRealTypeName() {
        let expectedFoo = Class(name: "Foo")
        let expectedClass = Class(name: "Bar", inheritedTypes: ["Foo"])
        expectedClass.inherits = ["Foo": expectedFoo]

        let types = sut.compose("""
        typealias GlobalAliasFoo = Foo
        class Foo { }
        class Bar: GlobalAliasFoo {}
        """).types

        XCTAssertTrue(types.contains(expectedClass))
    }

    func test_typealias_andGlobalProtocolComposition_itReplacesVariableAliasTypeWithProtocolCompositionTypes() {
        let expectedProtocol1 = Protocol(name: "Foo")
        let expectedProtocol2 = Protocol(name: "Bar")
        let expectedProtocolComposition = ProtocolComposition(name: "GlobalComposition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])

        let type = sut.compose("""
        typealias GlobalComposition = Foo & Bar
        protocol Foo {}
        protocol Bar {}
        """).types.last as? ProtocolComposition

        XCTAssertEqual(type, expectedProtocolComposition)
        XCTAssertEqual(type?.composedTypes?.first, expectedProtocol1)
        XCTAssertEqual(type?.composedTypes?.last, expectedProtocol2)
    }

    func test_typealias_andGlobalProtocolComposition_itDeconstructsCompositionsOfProtocolsForImplements() {
        let expectedProtocol1 = Protocol(name: "Foo")
        let expectedProtocol2 = Protocol(name: "Bar")
        let expectedProtocolComposition = ProtocolComposition(name: "GlobalComposition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])

        let type = sut.compose("""
        typealias GlobalComposition = Foo & Bar
        protocol Foo {}
        protocol Bar {}
        class Implements: GlobalComposition {}
        """).types.last as? Class

        XCTAssertEqual(type?.implements, [
            expectedProtocol1.name: expectedProtocol1,
            expectedProtocol2.name: expectedProtocol2,
            expectedProtocolComposition.name: expectedProtocolComposition
        ])
    }

    func test_typealias_andGlobalProtocolComposition_itDeconstructsCompositionsOfProtocolsAndClassesForImplementsAndInherits() {
        let expectedProtocol = Protocol(name: "Foo")
        let expectedClass = Class(name: "Bar")
        let expectedProtocolComposition = ProtocolComposition(name: "GlobalComposition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])
        expectedProtocolComposition.inherits = ["Bar": expectedClass]

        let type = sut.compose("""
        typealias GlobalComposition = Foo & Bar
        protocol Foo {}
        class Bar {}
        class Implements: GlobalComposition {}
        """).types.last as? Class

        XCTAssertEqual(type?.implements, [
            expectedProtocol.name: expectedProtocol,
            expectedProtocolComposition.name: expectedProtocolComposition
        ])
        XCTAssertEqual(type?.inherits, [
            expectedClass.name: expectedClass
        ])
    }

    func test_localTypealias_itReplacesVariableAliasTypeWithActualType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"), definedInTypeName: TypeName(name: "Bar"))

        let type = sut.compose("""
        class Bar {
            typealias FooAlias = Foo
            var foo: FooAlias
        }
        class Foo {}
        """).types.first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itReplacesVariableAliasTypeWithActualContainedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Bar.Foo")), type: Class(name: "Foo", parent: Class(name: "Bar")), definedInTypeName: TypeName(name: "Bar"))

        let variable = sut.compose("""
        class Bar {
            typealias FooAlias = Foo
            var foo: FooAlias
            class Foo {}
        }
        """).types.first?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itReplacesVariableAliasTypeWithActualForeignContainedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "FooBar.Foo")), type: Class(name: "Foo", parent: Type(name: "FooBar")), definedInTypeName: TypeName(name: "Bar"))

        let variable = sut.compose("""
        class Bar {
            typealias FooAlias = FooBar.Foo
            var foo: FooAlias
        }
        class FooBar { class Foo {} }
        """).types.first?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itPopulatesTheLocalCollectionOfTypealiases() {
        let expectedType = Class(name: "Foo")
        let expectedParent = Class(name: "Bar")
        let aliases = sut.compose("""
        class Bar { typealias FooAlias = Foo }
        class Foo {}
        """).types.first?.typealiases

        XCTAssertEqual(aliases?.count, 1)
        XCTAssertEqual(aliases?["FooAlias"], Typealias(aliasName: "FooAlias", typeName: TypeName(name: "Foo"), parent: expectedParent))
        XCTAssertEqual(aliases?["FooAlias"]?.type, expectedType)
    }

    func test_localTypealias_itPopulatesTheGlobalCollectionOfTypealiases() {
        let expectedType = Class(name: "Foo")
        let expectedParent = Class(name: "Bar")
        let aliases = sut.compose("""
        class Bar { typealias FooAlias = Foo }
        class Foo {}
        """).typealiases

        XCTAssertEqual(aliases.count, 1)
        XCTAssertEqual(aliases.first, Typealias(aliasName: "FooAlias", typeName: TypeName(name: "Foo"), parent: expectedParent))
        XCTAssertEqual(aliases.first?.type, expectedType)
    }

    func test_globalTypealias_itExtractsTypealiasesOfOtherTypealiases() {
        XCTAssertEqual(
            sut.compose("typealias Foo = Int; typealias Bar = Foo").typealiases,
            [
                Typealias(aliasName: "Bar", typeName: TypeName(name: "Foo")),
                Typealias(aliasName: "Foo", typeName: TypeName(name: "Int"))
            ]
        )
    }

    func test_globalTypealias_itExtractsTypealiasesOfOtherTypealiasesOfAType() {
        XCTAssertEqual(
            sut.compose("typealias Foo = Baz; typealias Bar = Foo; class Baz {}").typealiases,
            [
                Typealias(aliasName: "Bar", typeName: TypeName(name: "Foo")),
                Typealias(aliasName: "Foo", typeName: TypeName(name: "Baz"))
            ]
        )
    }

    func test_globalTypealias_itResolvesTypesTransitively() {
        let expectedType = Class(name: "Baz")

        let typealiases = sut.compose("typealias Foo = Bar; typealias Bar = Baz; class Baz {}").typealiases

        XCTAssertEqual(typealiases.count, 2)
        XCTAssertEqual(typealiases.first?.type, expectedType)
        XCTAssertEqual(typealiases.last?.type, expectedType)
    }

    func test_associatedValue_itExtractsType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))

        let types = sut.compose("protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar) }").types
        let parsedEnum = types.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedEnum, Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])]))
        XCTAssertEqual(associatedValue.type, parsedEnum?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsOptionalType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar?"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))

        let types = sut.compose("protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar?) }").types
        let parsedEnum = types.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedEnum, Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])]))
        XCTAssertEqual(associatedValue.type, parsedEnum?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsTypealias() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar2"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))

        let types = sut.compose("typealias Bar2 = Bar; protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar2) }").types
        let parsedEnum = types.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedEnum, Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])]))
        XCTAssertEqual(associatedValue.type, parsedEnum?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsSameIndirectEnumType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Foo"))
        let expectedEnum = Enum(name: "Foo", inheritedTypes: ["Baz"], cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])], modifiers: [
            Modifier(name: "indirect")
        ])
        associatedValue.type = expectedEnum

        let types = sut.compose("protocol Baz {}; indirect enum Foo: Baz { case optionA(Foo) }").types
        let parsedEnum = types.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedEnum, expectedEnum)
        XCTAssertEqual(associatedValue.type, parsedEnum?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedType_itExtractsTypeWhenConstrainedToTypealias() {
        let givenTypealias = Typealias(aliasName: "AEncodable", typeName: TypeName(name: "Encodable"))
        let expectedProtocol = Protocol(name: "Foo", typealiases: [givenTypealias])
        givenTypealias.parent = expectedProtocol
        expectedProtocol.associatedTypes["Bar"] = AssociatedType(
            name: "Bar",
            typeName: TypeName(
                name: givenTypealias.aliasName,
                actualTypeName: givenTypealias.typeName
            )
        )

        let actualProtocol = sut.compose("""
        protocol Foo {
            typealias AEncodable = Encodable
            associatedtype Bar: AEncodable
        }
        """).types.first

        XCTAssertEqual(actualProtocol, expectedProtocol)
        let actualTypeName = (actualProtocol as? SourceryProtocol)?.associatedTypes.first?.value.typeName?.actualTypeName
        XCTAssertEqual(actualTypeName, givenTypealias.actualTypeName)
    }

    func test_nestedType_itExtractsDefinedInType() {
        let expectedMethod = Function(name: "some()", selectorName: "some", definedInTypeName: TypeName(name: "Foo.Bar"))

        let types = sut.compose("class Foo { class Bar { func some() } }").types
        let method = types.last?.methods.first

        XCTAssertEqual(method, expectedMethod)
        XCTAssertEqual(method?.definedInType, types.last)
    }

    func test_nestedType_itExtractsPropertyOfNestedGenericType() {
        let expectedActualTypeName = TypeName(name: "Blah.Foo<Blah.FooBar>?")
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "Foo<FooBar>?", actualTypeName: expectedActualTypeName), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "FooBar"), Struct(name: "Foo<T>"), Struct(name: "Bar", variables: [expectedVariable])])
        expectedActualTypeName.generic = GenericType(name: "Blah.Foo", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Blah.FooBar"), type: expectedBlah.containedType["FooBar"])])
        expectedVariable.typeName.generic = expectedActualTypeName.generic

        let types = sut.compose("""
        struct Blah {
            struct FooBar {}
            struct Foo<T> {}
            struct Bar {
                let foo: Foo<FooBar>?
            }
        }
        """).types
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itExtractsPropertyOfNestedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "Foo?", actualTypeName: TypeName(name: "Blah.Foo?")), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "Foo"), Struct(name: "Bar", variables: [expectedVariable])])

        let types = sut.compose("struct Blah { struct Foo {}; struct Bar { let foo: Foo? }}").types
        let blah = types.first { $0.name == "Blah" }
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(blah, expectedBlah)
        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itExtractsPropertyOfNestedTypeArray() {
        let expectedActualTypeName = TypeName(name: "[Blah.Foo]?")
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "[Foo]?", actualTypeName: expectedActualTypeName), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "Foo"), Struct(name: "Bar", variables: [expectedVariable])])
        expectedActualTypeName.array = ArrayType(name: "[Blah.Foo]", elementTypeName: TypeName(name: "Blah.Foo"), elementType: Struct(name: "Foo", parent: expectedBlah))
        expectedVariable.typeName.array = expectedActualTypeName.array
        expectedActualTypeName.generic = GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo", parent: expectedBlah))])
        expectedVariable.typeName.generic = expectedActualTypeName.generic

        let types = sut.compose("struct Blah { struct Foo {}; struct Bar { let foo: [Foo]? }}").types
        let blah = types.first { $0.name == "Blah" }
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(blah, expectedBlah)
        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itExtractsPropertyOfNestedTypeDictionary() {
        let expectedActualTypeName = TypeName(name: "[Blah.Foo: Blah.Foo]?")
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "[Foo: Foo]?", actualTypeName: expectedActualTypeName), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "Foo"), Struct(name: "Bar", variables: [expectedVariable])])
        expectedActualTypeName.dictionary = DictionaryType(name: "[Blah.Foo: Blah.Foo]", valueTypeName: TypeName(name: "Blah.Foo"), valueType: Struct(name: "Foo", parent: expectedBlah), keyTypeName: TypeName(name: "Blah.Foo"), keyType: Struct(name: "Foo", parent: expectedBlah))
        expectedVariable.typeName.dictionary = expectedActualTypeName.dictionary
        expectedActualTypeName.generic = GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo", parent: expectedBlah)), GenericTypeParameter(typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo", parent: expectedBlah))])
        expectedVariable.typeName.generic = expectedActualTypeName.generic

        let types = sut.compose("struct Blah { struct Foo {}; struct Bar { let foo: [Foo: Foo]? }}").types
        let blah = types.first { $0.name == "Blah" }
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(blah, expectedBlah)
        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itExtractsPropertyOfNestedTypeTuple() {
        let expectedActualTypeName = TypeName(
            name: "(Blah.Foo, Blah.Foo, Blah.Foo)?",
            tuple: TupleType(
                name: "(Blah.Foo, Blah.Foo, Blah.Foo)", 
                elements: [
                    TupleElement(name: "a", typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo")),
                    TupleElement(name: "1", typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo")),
                    TupleElement(name: "2", typeName: TypeName(name: "Blah.Foo"), type: Struct(name: "Foo"))
                ]
            )
        )
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "(a: Foo, _: Foo, Foo)?", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "Foo"), Struct(name: "Bar", variables: [expectedVariable])])

        let types = sut.compose("struct Blah { struct Foo {}; struct Bar { let foo: (a: Foo, _: Foo, Foo)? }}").types
        let blah = types.first { $0.name == "Blah" }
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(blah, expectedBlah)
        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itResolvesProtocolGenericRequirementTypesAndInheritsAssociatedTypes() {
        let expectedRightType = Struct(name: "RightType")
        let genericProtocol = Protocol(name: "GenericProtocol", associatedTypes: ["LeftType": AssociatedType(name: "LeftType")])
        let expectedProtocol = Protocol(name: "SomeGenericProtocol", inheritedTypes: ["GenericProtocol"])
        expectedProtocol.associatedTypes = genericProtocol.associatedTypes
        expectedProtocol.genericRequirements = [
            GenericRequirement(
                leftType: .init(name: "LeftType"),
                rightType: GenericTypeParameter(typeName: TypeName(name: "RightType"), type: expectedRightType),
                relationship: .equals
            )
        ]

        let types = sut.compose("""
        struct RightType {}
        protocol GenericProtocol {
            associatedtype LeftType
        }
        protocol SomeGenericProtocol: GenericProtocol where LeftType == RightType {}
        """).types
        let parsedProtocol = types.first { $0.name == "SomeGenericProtocol" } as? SourceryProtocol

        XCTAssertEqual(parsedProtocol, expectedProtocol)
        XCTAssertEqual(parsedProtocol?.associatedTypes, genericProtocol.associatedTypes)
        XCTAssertEqual(parsedProtocol?.implements["GenericProtocol"], genericProtocol)
        XCTAssertEqual(parsedProtocol?.genericRequirements[0].rightType.type, expectedRightType)
    }

    func test_typesWithinModules_itDoesNotAutomaticallyAddModuleNameToUnknownTypesButKeepsTheInfoInTheASTviaModuleProperty() {
        let extensionType = Type(name: "AnyPublisher", isExtension: true).asUnknownException()
        extensionType.module = "MyModule"

        let types = [
            Module(name: "MyModule", content: """
            extension AnyPublisher {}
            struct Foo {
                var publisher: AnyPublisher<TimeInterval, Never>
            }
            """)
        ].parse().types
        let publisher = types.first
        let fooVariable = types.last?.variables.last

        XCTAssertEqual(publisher, extensionType)
        XCTAssertEqual(publisher?.globalName, "AnyPublisher")
        XCTAssertEqual(fooVariable?.typeName.generic?.name, "AnyPublisher")
    }

    func test_typesWithinModules_itCombinesUnknownExtensions() {
        let extensionType = Type(name: "AnyPublisher", isExtension: true, variables: [
            .init(name: "property1", typeName: .Int, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "AnyPublisher")),
            .init(name: "property2", typeName: .String, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "AnyPublisher"))
        ])
        extensionType.isUnknownExtension = true
        extensionType.module = "MyModule"

        let types = [
            Module(name: "MyModule", content: """
            extension AnyPublisher {}
            extension AnyPublisher {
                var property1: Int { 0 }
                var property2: String { "" }
            }
            """)
        ].parse().types

        XCTAssertEqual(types, [extensionType])
        XCTAssertEqual(types.first?.globalName, "AnyPublisher")
    }

    func test_typesWithinModules_itCombinesUnknownExtensionsFromDifferentFiles() {
        let extensionType = Type(name: "AnyPublisher", isExtension: true, variables: [
            .init(name: "property1", typeName: .Int, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "AnyPublisher")),
            .init(name: "property2", typeName: .String, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "AnyPublisher"))
        ])
        extensionType.isUnknownExtension = true
        extensionType.module = "MyModule"

        let types = [
            Module(name: "MyModule", content: """
            extension AnyPublisher {
                var property1: Int { 0 }
            }
            """),
            Module(name: "MyModule", content: """
            extension AnyPublisher {
                var property2: String { "" }
            }
            """)
        ].parse().types

        XCTAssertEqual(types, [extensionType])
        XCTAssertEqual(types.first?.globalName, "AnyPublisher")
    }

    func test_typesWithinModules_itCombinesKnownTypesWithExtensions() {
        let fooType = Struct(name: "Foo", variables: [
            .init(name: "property1", typeName: .Int, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "Foo")),
            .init(name: "property2", typeName: .String, accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "Foo"))
        ])
        fooType.module = "MyModule"

        let types = [
            Module(name: "MyModule", content: """
            struct Foo {}
            extension Foo {}
            extension Foo {
                var property1: Int { 0 }
                var property2: String { "" }
            }
            """)
        ].parse().types

        XCTAssertEqual(types, [fooType])
        XCTAssertEqual(types.first?.globalName, "MyModule.Foo")
    }

    func test_typesWithinModules_andGlobalNames_itExtendsTypeWithExtension() {
        let expectedBar = Struct(name: "Bar", variables: [
            Variable(name: "foo", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, definedInTypeName: TypeName(name: "MyModule.Bar"))
        ])
        expectedBar.module = "MyModule"

        let types = [
            Module(name: "MyModule", content: "struct Bar {}"),
            Module(name: nil, content: "extension MyModule.Bar { var foo: Int { return 0 } }")
        ].parse().types

        XCTAssertEqual(types, [expectedBar])
    }

    func test_typesWithinModules_andGlobalNames_itResolvesVariableType() {
        let expectedBar = Struct(name: "Bar")
        expectedBar.module = "MyModule"
        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "MyModule.Bar"), type: expectedBar, definedInTypeName: TypeName(name: "Foo"))])

        let types = [
            Module(name: "MyModule", content: "struct Bar {}"),
            Module(name: nil, content: "struct Foo { var bar: MyModule.Bar }")
        ].parse().types

        XCTAssertEqual(types, [expectedFoo, expectedBar])
        XCTAssertEqual(types.first?.variables.first?.type, expectedBar)
    }

    func test_typesWithinModules_andGlobalNames_itResolvesVariableDefinedInType() {
        let expectedBar = Struct(name: "Bar")
        expectedBar.module = "MyModule"
        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "MyModule.Bar"), type: expectedBar, definedInTypeName: TypeName(name: "Foo"))])

        let types = [
            Module(name: "MyModule", content: "struct Bar {}"),
            Module(name: nil, content: "struct Foo { var bar: MyModule.Bar }")
        ].parse().types

        XCTAssertEqual(types, [expectedFoo, expectedBar])
        XCTAssertEqual(types.first?.variables.first?.type, expectedBar)
        XCTAssertEqual(types.first?.variables.first?.definedInType, expectedFoo)
    }

    func test_typesWithinModules_andLocalNames_itResolvesVariableType() {
        let expectedBarA = Struct(name: "Bar")
        expectedBarA.module = "ModuleA"

        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "Bar"), type: expectedBarA, definedInTypeName: TypeName(name: "Foo"))])
        expectedFoo.module = "ModuleB"
        expectedFoo.imports = [Import(path: "ModuleA")]

        let expectedBarC = Struct(name: "Bar")
        expectedBarC.module = "ModuleC"

        let types = [
            Module(name: "ModuleA", content: "struct Bar {}"),
            Module(name: "ModuleB", content: """
            import ModuleA
            struct Foo { var bar: Bar }
            """),
            Module(name: "ModuleC", content: "struct Bar {}")
        ].parse().types

        XCTAssertEqual(types, [expectedBarA, expectedFoo, expectedBarC])
        XCTAssertEqual(types.first { $0.name == "Foo" }?.variables.first?.type, expectedBarA)
    }

    func test_typesWithinModules_andLocalNames_itResolvesVariableTypeWithinSameModule() {
        let expectedBar = Struct(name: "Bar", variables: [
            Variable(name: "bat", typeName: TypeName(name: "Int"), type: nil, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo.Bar"))
        ])
        expectedBar.module = "Foo"

        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "Bar"), type: expectedBar, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo"))], containedTypes: [expectedBar])
        expectedFoo.module = "Foo"

        let types = [
            Module(name: "Foo", content: """
            struct Foo {
                struct Bar {
                    let bat: Int
                }
                let bar: Bar
            }
            """)
        ].parse().types

        XCTAssertEqual(types, [expectedFoo, expectedBar])

        let parsedFoo = types.first { $0.globalName == "Foo.Foo" }
        XCTAssertEqual(parsedFoo, expectedFoo)
        XCTAssertEqual(parsedFoo?.variables.first?.type, expectedBar)
    }

    func test_typesWithinModules_andLocalNames_itResolvesVariableTypeEvenWhenUsingSpecializedImports() {
        let expectedBarA = Struct(name: "Bar")
        expectedBarA.module = "ModuleA.Submodule"

        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "Bar"), type: expectedBarA, definedInTypeName: TypeName(name: "Foo"))])
        expectedFoo.module = "ModuleB"
        expectedFoo.imports = [Import(path: "ModuleA.Submodule.Bar", kind: "struct")]

        let expectedBarC = Struct(name: "Bar")
        expectedBarC.module = "ModuleC"

        let types = [
            Module(name: "ModuleA.Submodule", content: "struct Bar {}"),
            Module(name: "ModuleB", content: """
            import struct ModuleA.Submodule.Bar
            struct Foo { var bar: Bar }
            """),
            Module(name: "ModuleC", content: "struct Bar {}")
        ].parse().types

        XCTAssertEqual(types, [expectedBarA, expectedFoo, expectedBarC])
        XCTAssertEqual(types.first { $0.name == "Foo" }?.variables.first?.type, expectedBarA)
    }

    func test_typesWithinModules_andLocalNames_itThrowsErrorWhenVariableTypeIsAmbigious() {
        let expectedBarA = Struct(name: "Bar")
        expectedBarA.module = "ModuleA"

        let expectedFoo = Struct(name: "Foo", variables: [Variable(name: "bar", typeName: TypeName(name: "Bar"), type: expectedBarA, definedInTypeName: TypeName(name: "Foo"))])
        expectedFoo.module = "ModuleB"

        let expectedBarC = Struct(name: "Bar")
        expectedBarC.module = "ModuleC"

        let types = [
            Module(name: "ModuleA", content: "struct Bar {}"),
            Module(name: "ModuleB", content: "struct Foo { var bar: Bar }"),
            Module(name: "ModuleC", content: "struct Bar {}")
        ].parse().types

        let barVariable = types.last?.variables.first

        XCTAssertEqual(types, [expectedBarA, expectedFoo, expectedBarC])
        XCTAssertEqual(barVariable?.typeName, nil)
        XCTAssertEqual(barVariable?.type, nil)
    }

    func test_typesWithinModules_andLocalNames_itResolvesVariableTypeWhenGenericsAreUsed() {
        let expectedBar = Struct(name: "Bar", variables: [
            Variable(name: "batDouble", typeName: TypeName(name: "Double"), type: nil, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo.Bar")),
            Variable(name: "batInt", typeName: TypeName(name: "Int"), type: nil, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo.Bar"))
        ])
        expectedBar.module = "ModuleA"

        let expectedBaz = Struct(name: "Baz", isGeneric: true)
        expectedBaz.module = "ModuleA"

        let expectedFoo = Struct(name: "Foo", variables: [
            Variable(name: "bar", typeName: TypeName(name: "Bar"), type: expectedBar, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo")),
            Variable(name: "bazbars", typeName: TypeName(name: "Baz<Bar>", generic: .init(name: "ModuleA.Foo.Baz", typeParameters: [.init(typeName: .init("ModuleA.Foo.Bar"))])), type: expectedBaz, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo")),
            Variable(name: "bazDoubles", typeName: TypeName(name: "Baz<Double>", generic: .init(name: "ModuleA.Foo.Baz", typeParameters: [.init(typeName: .init("Double"))])), type: expectedBaz, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo")),
            Variable(name: "bazInts", typeName: TypeName(name: "Baz<Int>", generic: .init(name: "ModuleA.Foo.Baz", typeParameters: [.init(typeName: .init("Int"))])), type: expectedBaz, accessLevel: (.internal, .none), definedInTypeName: TypeName(name: "Foo"))
        ], containedTypes: [expectedBar, expectedBaz])
        expectedFoo.module = "ModuleA"

        let expectedDouble = Type(name: "Double", accessLevel: .internal, isExtension: true).asUnknownException()
        expectedDouble.module = "ModuleA"

        let types = [
            Module(name: "ModuleA", content: """
            extension Double {}
            struct Foo {
                struct Bar {
                    let batDouble: Double
                    let batInt: Int
                }

                struct Baz<T> {
                }

                let bar: Bar
                let bazbars: Baz<Bar>
                let bazDoubles: Baz<Double>
                let bazInts: Baz<Int>
            }
            """)
        ].parse().types

        XCTAssertEqual(types, [expectedDouble, expectedFoo, expectedBar, expectedBaz])

        func assert(variable: String, typeName: String?, type: String?, onType globalName: String, file: StaticString = #filePath, line: UInt = #line) {
            do {
                let entity = try XCTUnwrap(types.first { $0.globalName == globalName }, file: file, line: line)
                let variable = try XCTUnwrap(entity.allVariables.first { $0.name == variable }, file: file, line: line)

                XCTAssertEqual(variable.typeName.description, typeName, file: file, line: line)
                XCTAssertEqual(variable.type?.name, type, file: file, line: line)
            } catch {
                return
            }
        }

        assert(variable: "bar", typeName: "Bar", type: "Foo.Bar", onType: "ModuleA.Foo")
        assert(variable: "bazbars", typeName: "Baz<Bar>", type: "Foo.Baz", onType: "ModuleA.Foo")
        assert(variable: "bazDoubles", typeName: "Baz<Double>", type: "Foo.Baz", onType: "ModuleA.Foo")
        assert(variable: "bazInts", typeName: "Baz<Int>", type: "Foo.Baz", onType: "ModuleA.Foo")
        assert(variable: "batDouble", typeName: "Double", type: "Double", onType: "ModuleA.Foo.Bar")
        assert(variable: "batInt", typeName: "Int", type: nil, onType: "ModuleA.Foo.Bar")
    }

    func test_freeFunction_itResolvesGenericReturnTypes() {
        let functions = sut.compose("func foo() -> Bar<String> { }").functions
        XCTAssertEqual(functions[0], Function(
            name: "foo()",
            selectorName: "foo",
            parameters: [],
            returnTypeName: TypeName(
                name: "Bar<String>",
                generic: GenericType(
                    name: "Bar",
                    typeParameters: [
                        GenericTypeParameter(
                            typeName: TypeName(name: "String"),
                            type: nil
                        )
                    ]
                )
            ),
            definedInTypeName: nil)
        )
    }

    func test_freeFunction_itResolvesTupleReturnTypes() {
        let functions = sut.compose("func foo() -> (bar: String, biz: Int) { }").functions
        XCTAssertEqual(functions[0], Function(
            name: "foo()",
            selectorName: "foo",
            parameters: [],
            returnTypeName: TypeName(
                name: "(bar: String, biz: Int)",
                tuple: TupleType(
                    name: "(bar: String, biz: Int)",
                    elements: [
                        TupleElement(name: "bar", typeName: TypeName(name: "String")),
                        TupleElement(name: "biz", typeName: TypeName(name: "Int"))
                    ]
                )
            ),
            definedInTypeName: nil
        ))
    }

    func test_nestedTypes_itResolveExtensionsOfNestedType() {
        let types = [
            Module(name: "Mod1", content: "enum NS {}; extension NS { struct Foo { func f1() } }"),
            Module(name: "Mod2", content: "import Mod1; extension NS.Foo { func f2() }"),
            Module(name: "Mod3", content: "import Mod1; extension NS.Foo { func f3() }")
        ].parse().types
        XCTAssertEqual(types.map { $0.globalName }, ["Mod1.NS", "Mod1.NS.Foo"])
        XCTAssertEqual(types[1].methods.map { $0.name }, ["f1()", "f2()", "f3()"])
    }

    func test_nestedTypes_itResolveExtensionsWithNestedTypes() {
        let types = [
            Module(name: "Mod1", content: "enum NS {}"),
            Module(name: "Mod2", content: "import Mod1; extension NS { struct A {} }"),
            Module(name: "Mod3", content: "import Mod1; extension NS { struct B {} }")
        ].parse().types
        XCTAssertEqual(types.map { $0.globalName }, ["Mod1.NS", "Mod2.NS.A", "Mod3.NS.B"])
    }

    func test_nestedTypes_itResolvesExtensionsOfNestedTypes() {
        let code = """
        struct Root {
            struct ViewState {}
        }

        extension Root.ViewState {
            struct Item: AutoInitializable {
            }
        }

        extension Root.ViewState.Item {
            struct ChildItem {}
        }
        """

        let types = [Module(name: "Mod1", content: code)].parse().types

        XCTAssertEqual(types.map { $0.globalName }, [
            "Mod1.Root",
            "Mod1.Root.ViewState",
            "Mod1.Root.ViewState.Item",
            "Mod1.Root.ViewState.Item.ChildItem"
        ])
    }

    func test_protocolsOfTheSameNameInDifferentModules_itResolvesTypes() {
        let types = [
            Module(name: "Mod1", content: "protocol Foo { func foo1() }"),
            Module(name: "Mod2", content: "protocol Foo { func foo2() }")
        ].parse().types

        XCTAssertEqual(types.first?.globalName, "Mod1.Foo")
        XCTAssertEqual(types.first?.allMethods.map { $0.name }, ["foo1()"])
        XCTAssertEqual(types.last?.globalName, "Mod2.Foo")
        XCTAssertEqual(types.last?.allMethods.map { $0.name }, ["foo2()"])
    }

    func test_protocolsOfTheSameNameInDifferentModules_itResolvesInheritanceWithGlobalTypeName() {
        let types = [
            Module(name: "Mod1", content: "protocol Foo { func foo1() }"),
            Module(name: "Mod2", content: "protocol Foo { func foo2() }"),
            Module(name: "Mod3", content: "import Mod1; import Mod2; protocol Bar: Mod1.Foo { func bar() }")
        ].parse().types
        let bar = types.first { $0.name == "Bar" }

        XCTAssertEqual(bar?.allMethods.map { $0.name }.sorted(), ["bar()", "foo1()"])
    }

    func test_protocolsOfTheSameNameInDifferentModules_itResolvesInheritanceWithLocalTypeName() {
        let types = [
            Module(name: "Mod1", content: "protocol Foo { func foo1() }"),
            Module(name: "Mod2", content: "protocol Foo { func foo2() }"),
            Module(name: "Mod3", content: "import Mod1; protocol Bar: Foo { func bar() }")
        ].parse().types
        let bar = types.first { $0.name == "Bar"}

        XCTAssertEqual(bar?.allMethods.map { $0.name }.sorted(), ["bar()", "foo1()"])
    }
}

private extension Composer {
    func compose(_ content: String) -> (types: [Type], functions: [Function], typealiases: [Typealias]) {
        let parserResult = SwiftSyntaxParser().parse(content)
        return compose(
            functions: parserResult.functions,
            typealiases: parserResult.typealiases,
            types: parserResult.types
        )
    }
}

private struct Module {
    let name: String?
    let content: String
}

private extension Array where Element == Module {
    func parse() -> (types: [Type], functions: [Function], typealiases: [Typealias]) {
        let results = map {
            SwiftSyntaxParser().parse($0.content, module: $0.name)
        }

        var allFunctions: [Function] = []
        var allTypealiases: [Typealias] = []
        var allTypes: [Type] = []

        for result in results {
            allFunctions += result.functions
            allTypealiases += result.typealiases
            allTypes += result.types
        }

        return Composer().compose(
            functions: allFunctions,
            typealiases: allTypealiases,
            types: allTypes
        )
    }
}
