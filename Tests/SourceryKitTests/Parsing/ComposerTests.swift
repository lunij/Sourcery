import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class ComposerTests: XCTestCase {
    private func createGivenClassHierarchyScenario() -> (fooType: Type, barType: Type, bazType: Type) {
        let parsedResult = """
        class Foo {
            var foo: Int;
            func fooMethod() {}
        }
        class Bar: Foo {
            var bar: Int
        }
        class Baz: Bar {
            var baz: Int;
            func bazMethod() {}
        }
        """.parse()
        return (
            parsedResult[2],
            parsedResult[0],
            parsedResult[1]
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
        let types = """
        class Foo { func foo() -> Bar { } }
        class Bar {}
        """.parse()
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
        let types = """
        class Foo {
            func foo<T: Equatable>() -> Bar?\n where \nT: Equatable {
            };  /// Asks a Duck to quack
                ///
                /// - Parameter times: How many times the Duck will quack
            func fooBar<T>(bar: T) where T: Equatable { }
        };
        class Bar {}
        """.parse()
        assertMethods(types)
    }

    func test_genericMethod_itExtractsProtocolMethod() {
        let types = """
        protocol Foo {
            func foo<T: Equatable>() -> Bar?\n where \nT: Equatable  /// Asks a Duck to quack
                ///
                /// - Parameter times: How many times the Duck will quack
            func fooBar<T>(bar: T) where T: Equatable
        };
        class Bar {}
        """.parse()
        assertMethods(types)
    }

    func test_initializer_itExtractsInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Method(name: "init()", selectorName: "init", returnTypeName: TypeName(name: "Foo"), isStatic: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Method(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = "class Foo { func foo() {}; init() {} }".parse().first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
        XCTAssertEqual(initializer?.returnType, fooType)
    }

    func test_initializer_itExtractsFailableInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Method(name: "init?()", selectorName: "init", returnTypeName: TypeName(name: "Foo?"), isStatic: true, isFailableInitializer: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Method(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = "class Foo { func foo() {}; init?() {} }".parse().first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
        XCTAssertEqual(initializer?.returnType, fooType)
    }

    func test_protocolInheritance_itFlattensProtocolWithDefaultImplementation() {
        let parsed = """
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
        """.parse()

        XCTAssertEqual(parsed.count, 1)

        let childProtocol = parsed.last
        XCTAssertEqual(childProtocol?.name, "UrlOpening")
        XCTAssertEqual(childProtocol?.allMethods.map { $0.selectorName }, ["open(_:options:completionHandler:)", "open(_:)", "anotherFunction(key:)"])
    }

    func test_protocolInheritance_itFlattensInheritedProtocolsWithDefaultImplementation() {
        let parsed = """
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
        """.parse()

        XCTAssertEqual(parsed.count, 2)

        let childProtocol = parsed.last
        XCTAssertEqual(childProtocol?.name, "UrlOpening")
        XCTAssertEqual(childProtocol?.allMethods.filter({ $0.definedInType?.isExtension == false }).map { $0.selectorName }, ["open(_:options:completionHandler:)", "open(_:)"])
    }

    private func createOverlappingProtocolInheritanceScenario() -> (
        baseProtocol: Type,
        baseClass: Type,
        extendedProtocol: Type,
        extendedClass: Type
    ) {
        let parsedResult = """
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
        """.parse()
        return (
            parsedResult[1],
            parsedResult[0],
            parsedResult[3],
            parsedResult[2]
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
        let innerType = Struct(name: "Bar", accessLevel: .internal, isExtension: false, variables: [])

        XCTAssertEqual("struct Foo {}  extension Foo { struct Bar { } }".parse(), [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], containedTypes: [innerType]),
            innerType
        ])
    }

    func test_extensionOfSameType_itCombinesMethods() {
        XCTAssertEqual("class Baz {}; extension Baz { func foo() {} }".parse(), [
            Class(name: "Baz", methods: [
                Method(name: "foo()", selectorName: "foo", accessLevel: .internal, definedInTypeName: TypeName(name: "Baz"))
            ])
        ])
    }

    func test_extensionOfSameType_itCombinesVariables() {
        XCTAssertEqual("class Baz {}; extension Baz { var foo: Int }".parse(), [
            Class(name: "Baz", variables: [
                .init(name: "foo", typeName: .Int, definedInTypeName: TypeName(name: "Baz"))
            ])
        ])
    }

    func test_extensionOfSameType_itCombinesVariablesAndMethodsWithAccessInformationFromTheExtension() {
        let foo = Struct(name: "Foo", accessLevel: .public, isExtension: false, variables: [.init(name: "boo", typeName: .Int, accessLevel: (.public, .none), isComputed: true, definedInTypeName: TypeName(name: "Foo"))], methods: [.init(name: "foo()", selectorName: "foo", accessLevel: .public, definedInTypeName: TypeName(name: "Foo"))], modifiers: [.init(name: "public")])

        XCTAssertEqual(
            """
            public struct Foo { }
            public extension Foo {
              func foo() { }
              var boo: Int { 0 }
            }
            """.parse().last, foo
        )
    }

    func test_extensionOfSameType_itCombinesInheritedTypes() {
        XCTAssertEqual("class Foo: TestProtocol { }; extension Foo: AnotherProtocol {}".parse(), [
            Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol", "AnotherProtocol"])
        ])
    }

    func test_extensionOfSameType_itDoesNotUseExtensionToInferEnumRawType() {
        XCTAssertEqual("enum Foo { case one }; extension Foo: Equatable {}".parse(), [
            Enum(name: "Foo",
                 inheritedTypes: ["Equatable"],
                 cases: [EnumCase(name: "one")]
            )
        ])
    }

    private func createOriginalDefinitionTypeScenario() -> (SourceryRuntime.Method, SourceryRuntime.Method) {
        let method = Method(
            name: "fooMethod(bar: String)",
            selectorName: "fooMethod(bar:)",
            parameters: [
                MethodParameter(name: "bar", typeName: TypeName(name: "String"))
            ],
            returnTypeName: TypeName(name: "Void"),
            definedInTypeName: TypeName(name: "Foo")
        )
        let defaultedMethod = Method(
            name: "fooMethod(bar: String = \"Baz\")",
            selectorName: "fooMethod(bar:)",
            parameters: [
                MethodParameter(name: "bar", typeName: TypeName(name: "String"), defaultValue: "\"Baz\"")
            ],
            returnTypeName: TypeName(name: "Void"),
            accessLevel: .internal,
            definedInTypeName: TypeName(name: "Foo")
        )
        return (method, defaultedMethod)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andEnum_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let input = "enum Foo { case A; func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }"
        let parsedResult = input.parse().first
        let originalType = Enum(name: "Foo", cases: [EnumCase(name: "A")], methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(parsedResult?.methods.first?.definedInType, originalType)
        XCTAssertEqual(parsedResult?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andProtocol_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let input = "protocol Foo { func \(method.name) }; extension Foo { func \(defaultedMethod.name) {} }"
        let parsedResult = input.parse().first
        let originalType = Protocol(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(parsedResult?.methods.first?.definedInType, originalType)
        XCTAssertEqual(parsedResult?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andClass_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let input = "class Foo { func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }"
        let parsedResult = input.parse().first
        let originalType = Class(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(parsedResult?.methods.first?.definedInType, originalType)
        XCTAssertEqual(parsedResult?.methods.last?.definedInType, typeExtension)
    }

    func test_extensionOfSameType_andRemembersOriginalDefinitionType_andStruct_itResolvesMethodsDefinedInType() {
        let (method, defaultedMethod) = createOriginalDefinitionTypeScenario()
        let input = "struct Foo { func \(method.name) {} }; extension Foo { func \(defaultedMethod.name) {} }"
        let parsedResult = input.parse().first
        let originalType = Struct(name: "Foo", methods: [method, defaultedMethod])
        let typeExtension = Type(name: "Foo", accessLevel: .internal, isExtension: true, methods: [defaultedMethod])

        XCTAssertEqual(parsedResult?.methods.first?.definedInType, originalType)
        XCTAssertEqual(parsedResult?.methods.last?.definedInType, typeExtension)
    }

    func test_enumContainingAssociatedValues_itTrimsWhitespaceFromAssociatedValueNames() {
        XCTAssertEqual(
            "enum Foo {\n case bar(\nvalue: String,\n other: Int\n)\n}".parse(),
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
            "enum Foo: String, SomeProtocol { case optionA }; protocol SomeProtocol {}".parse(),
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
            "enum Foo: RawRepresentable { case optionA; var rawValue: String { return \"\" }; init?(rawValue: String) { self = .optionA } }".parse(),
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
                        Method(
                            name: "init?(rawValue: String)",
                            selectorName: "init(rawValue:)",
                            parameters: [MethodParameter(name: "rawValue",typeName: TypeName(name: "String"))],
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
            """
            enum Foo: RawRepresentable {
                case optionA
                typealias RawValue = String
                var rawValue: RawValue { return \"\" }
                init?(rawValue: RawValue) { self = .optionA }
            }
            """.parse(),
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
                        Method(
                            name: "init?(rawValue: RawValue)",
                            selectorName: "init(rawValue:)",
                            parameters: [MethodParameter(name: "rawValue", typeName: TypeName(name: "RawValue"))],
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
            """
            enum Foo: CustomStringConvertible, RawRepresentable {
                case optionA
                typealias RawValue = String
                var rawValue: RawValue { return \"\" }
                init?(rawValue: RawValue) { self = .optionA }
            }
            """.parse(),
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
                        Method(
                            name: "init?(rawValue: RawValue)",
                            selectorName: "init(rawValue:)",
                            parameters: [MethodParameter(name: "rawValue", typeName: TypeName(name: "RawValue"))],
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
            "enum Enum: SomeProtocol { case optionA }".parse().first(where: { $0.name == "Enum" }),
            // ATM it is expected that we assume that first inherited type is a raw value type. To avoid that client code should specify inherited type via extension
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"], rawTypeName: TypeName(name: "SomeProtocol"), cases: [EnumCase(name: "optionA")])
        )
    }

    func test_enumWithoutRawTypeWithInheritingType_itDoesNotSetInheritedTypeToRawValueTypeForEnumCasesWithAssociatedValues() {
        XCTAssertEqual(
            "enum Enum: SomeProtocol { case optionA(Int); case optionB;  }".parse().first(where: { $0.name == "Enum" }),
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"], cases: [
                EnumCase(name: "optionA", associatedValues: [AssociatedValue(typeName: TypeName(name: "Int"))]),
                EnumCase(name: "optionB")
            ])
        )
    }

    func test_enumWithoutRawTypeWithInheritingType_itDoesNotSetInheritedTypeToRawValueTypeForEnumWithNoCases() {
        XCTAssertEqual(
            "enum Enum: SomeProtocol { }".parse().first(where: { $0.name == "Enum" }),
            Enum(name: "Enum", inheritedTypes: ["SomeProtocol"])
        )
    }

    func test_enumInheritingProtocolComposition_itExtractsTheProtocolCompositionAsTheInheritedType() {
        XCTAssertEqual(
            "enum Enum: Composition { }; typealias Composition = Foo & Bar; protocol Foo {}; protocol Bar {}".parse().first(where: { $0.name == "Enum" }),
            Enum(name: "Enum", inheritedTypes: ["Composition"])
        )
    }

    func test_genericCustomType_itExtractsGenericTypeName() throws {
        let types = """
        struct GenericArgumentStruct<T> {
            let value: T
        }

        struct Foo {
            var value: GenericArgumentStruct<Bool>
        }
        """.parse()

        let foo = try XCTUnwrap(types.first { $0.name == "Foo" })
        let fooGeneric = try XCTUnwrap(foo.instanceVariables.first?.typeName.generic)

        XCTAssertTrue(types.contains { $0.name == "GenericArgumentStruct" })
        XCTAssertEqual(fooGeneric.typeParameters.count, 1)
        XCTAssertEqual(fooGeneric.typeParameters.first?.typeName.name, "Bool")
    }

    func test_tupleType_itExtractsElements() {
        let types = """
        struct Foo {
            var tuple: (a: Int, b: Int, String, _: Float, literal: [String: [String: Float]], generic: Dictionary<String, Dictionary<String, Float>>, closure: (Int) -> (Int) -> Int, tuple: (Int, Int))
        }
        """.parse()
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
        let types = """
        struct Foo {
            var array: [Int]
            var arrayOfTuples: [(Int, Int)]
            var arrayOfArrays: [[Int]], var arrayOfClosures: [() -> ()] 
        }
        """.parse()
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
        let types = """
        struct Foo {
            var array: Array<Int>
            var arrayOfTuples: Array<(Int, Int)>
            var arrayOfArrays: Array<Array<Int>>, var arrayOfClosures: Array<() -> ()>
        }
        """.parse()
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
        let types = """
        struct Foo {
            var dictionary: Dictionary<Int, String>
            var dictionaryOfArrays: Dictionary<[Int], [String]>
            var dictonaryOfDictionaries: Dictionary<Int, [Int: String]>
            var dictionaryOfTuples: Dictionary<Int, (String, String)>
            var dictionaryOfClosures: Dictionary<Int, () -> ()>
        }
        """.parse()
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
        let types = """
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
        """.parse()
        let bar = SourceryProtocol.init(name: "Bar")
        let variables = types[3].variables
        XCTAssertEqual(variables[0].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[1].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[2].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[3].type?.implements["Bar"], bar)
        XCTAssertEqual(variables[4].type?.implements["Bar"], bar)
    }

    func test_literalDictionaryType_itExtractsKeyType() {
        let types = """
        struct Foo {
            var dictionary: [Int: String]
            var dictionaryOfArrays: [[Int]: [String]]
            var dicitonaryOfDictionaries: [Int: [Int: String]]
            var dictionaryOfTuples: [Int: (String, String)]
            var dictionaryOfClojures: [Int: () -> ()]
        }
        """.parse()
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
        let types = "struct Foo { var closure: () -> \n Int }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Int", parameters: [], returnTypeName: TypeName(name: "Int"))
        )
    }

    func test_closureType_itExtractsThrowsReturnType() {
        let types = "struct Foo { var closure: () throws -> Int }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() throws -> Int", parameters: [], returnTypeName: TypeName(name: "Int"), throwsOrRethrowsKeyword: "throws")
        )
    }

    func test_closureType_itExtractsVoidReturnType() {
        let types = "struct Foo { var closure: () -> Void }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Void", parameters: [], returnTypeName: TypeName(name: "Void"))
        )
    }

    func test_closureType_itExtractsVoidAsParanthesesReturnType() {
        let types = "struct Foo { var closure: () -> () }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> ()", parameters: [], returnTypeName: TypeName(name: "()"))
        )
    }

    func test_closureType_itExtractsComplexClosureType() {
        let types = "struct Foo { var closure: () -> (Int) throws -> Int }".parse()
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
        let types = "struct Foo { var closure: () -> Int }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "() -> Int", parameters: [], returnTypeName: TypeName(name: "Int"))
        )
    }

    func test_closureType_itExtractsVoidParameters() {
        let types = "struct Foo { var closure: (Void) -> Int }".parse()
        let variables = types.first?.variables

        XCTAssertEqual(
            variables?[0].typeName.closure,
            ClosureType(name: "(Void) -> Int", parameters: [.init(typeName: TypeName(name: "Void"))], returnTypeName: .Int)
        )
    }

    func test_closureType_itExtractsParameters() {
        let types = "struct Foo { var closure: (Int, Int -> Int) -> Int }".parse()
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

        let types = """
        struct Foo {
            var variable: Self { .init() }

            struct SubType {
                static var staticVar: Self = .init()
            }
        }
        """.parse()

        func assert(_ variable: Variable?, expected: Variable, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(variable, expected, file: file, line: line)
            XCTAssertEqual(variable?.actualTypeName, expected.actualTypeName, file: file, line: line)
            XCTAssertEqual(variable?.type, expected.type, file: file, line: line)
        }

        assert(types.first(where: { $0.name == "Foo" })?.instanceVariables.first, expected: expectedVariable)
        assert(types.first(where: { $0.name == "Foo.SubType" })?.staticVariables.first, expected: expectedStaticVariable)
    }

    func test_selfInsteadOfTypeName_itReplacesMethodTypesWithActualTypes() {
        let expectedMethod = Method(
            name: "myMethod()",
            selectorName: "myMethod",
            returnTypeName: TypeName(name: "Self", actualTypeName: TypeName(name: "Foo.SubType")),
            definedInTypeName: TypeName(name: "Foo.SubType")
        )
        let subType = Struct(name: "SubType", methods: [expectedMethod])
        let fooType = Struct(name: "Foo", containedTypes: [subType])

        subType.parent = fooType

        let types = """
        struct Foo {
            struct SubType {
                func myMethod() -> Self {
                    return self
                }
            }
        }
        """.parse()

        let parsedSubType = types.first { $0.name == "Foo.SubType" }
        XCTAssertEqual(parsedSubType?.methods.first, expectedMethod)
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasChainToFinalType() {
        let typealiases = """
        enum Bar {}
        struct Foo {}
        typealias Root = Bar
        typealias Leaf1 = Root
        typealias Leaf2 = Leaf1
        typealias Leaf3 = Leaf1
        """.parse(\.typealiases)

        XCTAssertEqual(typealiases.count, 4)
        typealiases.forEach {
            XCTAssertEqual($0.type?.name, "Bar")
        }
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasChainContainedInTypesToFinalType() {
        let typealiases = """
        enum Bar {
            typealias Root = Bar
        }

        struct Foo {
            typealias Leaf1 = Bar.Root
        }
        typealias Leaf2 = Foo.Leaf1
        typealias Leaf3 = Leaf2
        typealias Leaf4 = Bar.Root
        """.parse(\.typealiases)

        XCTAssertEqual(typealiases.count, 5)
        typealiases.forEach {
              XCTAssertEqual($0.type?.name, "Bar")
        }
    }

    func test_typealiases_andUpdatedComposer_itFollowsThroughTypealiasContainedInOtherTypes() {
        let type = """
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
        """.parse()[2]

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
        let result = """
        typealias UnknownTypeAlias = Unknown
        extension UnknownTypeAlias {
            struct KnownStruct {
                var name: Int = 0
                var meh: Float = 0
            }
        }
        """.parse()
        let knownType = result.first { $0.localName == "KnownStruct" }

        XCTAssertEqual(knownType?.isExtension, false)
        XCTAssertEqual(knownType?.variables.count, 2)
    }

    func test_typealiases_andUpdatedComposer_itExtendsTheActualTypeWhenUsingTypealias() {
        let result = """
        struct Foo {
        }
        typealias FooAlias = Foo
        extension FooAlias {
            var name: Int { 0 }
        }
        """.parse()

        XCTAssertEqual(result.first?.variables.first?.typeName, TypeName.Int)
    }

    func test_typealiases_andUpdatedComposer_itResolvesInheritanceChainViaTypealias() {
        let result = """
        class Foo {
            class Inner {
                var innerBase: Bool
            }
            typealias Hidden = Inner
            class InnerInherited: Hidden {
                var innerInherited: Bool = true
            }
        }
        """.parse()
        let innerInherited = result.first { $0.localName == "InnerInherited" }

        XCTAssertEqual(innerInherited?.inheritedTypes, ["Foo.Inner"])
    }

    func test_typealiases_itResolvesDefinedInTypeForMethods() {
        let type = """
        class Foo { func bar() {} }
        typealias FooAlias = Foo
        extension FooAlias { func baz() {} }
        """.parse().first

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
        let type = """
        class Foo { var bar: Int { return 1 } }
        typealias FooAlias = Foo
        extension FooAlias { var baz: Int { return 2 } }
        """.parse().first

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
        let types = "class Bar {}; class Foo { typealias BarAlias = Bar }".parse()
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

        let type = """
        typealias GlobalAlias = Foo
        class Foo {}
        class Bar { var foo: GlobalAlias }
        """.parse().first
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

        let types = """
        typealias GlobalAlias = Foo
        class Foo {}
        class Bar { var foo: (GlobalAlias, Int) }
        """.parse()
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

        let type = """
        typealias GlobalAlias = (Foo, Int)
        class Foo {}
        class Bar { var foo: GlobalAlias }
        """.parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.typeName.isTuple, true)
    }

    func test_typealiases_andMethodReturnType_itReplacesMethodReturnTypeAliasWithActualType() {
        let expectedMethod = Method(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = "typealias FooAlias = Foo; class Foo {}; class Bar { func some() -> FooAlias }".parse()
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
        let expectedMethod = Method(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "(FooAlias, Int)", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = "typealias FooAlias = Foo; class Foo {}; class Bar { func some() -> (FooAlias, Int) }".parse()
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
        let expectedMethod = Method(
            name: "some()",
            selectorName: "some",
            returnTypeName: TypeName(name: "GlobalAlias", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple),
            definedInTypeName: TypeName(name: "Bar")
        )

        let types = "typealias GlobalAlias = (Foo, Int); class Foo {}; class Bar { func some() -> GlobalAlias }".parse()
        let method = types.first?.methods.first

        XCTAssertEqual(method, expectedMethod)
        XCTAssertEqual(method?.actualReturnTypeName, expectedMethod.actualReturnTypeName)
        XCTAssertEqual(method?.returnTypeName.isTuple, true)
    }

    func test_typealiases_andMethodParameter_itReplacesMethodParameterTypeAliasWithActualType() {
        let expectedMethodParameter = MethodParameter(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"))

        let types = """
        typealias FooAlias = Foo
        class Foo {}
        class Bar { func some(foo: FooAlias) }
        """.parse()
        let methodParameter = types.first?.methods.first?.parameters.first

        XCTAssertEqual(methodParameter, expectedMethodParameter)
        XCTAssertEqual(methodParameter?.actualTypeName, expectedMethodParameter.actualTypeName)
        XCTAssertEqual(methodParameter?.type, Class(name: "Foo"))
    }

    func test_typealiases_andMethodParameter_itReplacesTupleElementsAliasTypesWithActualTypes() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedMethodParameter = MethodParameter(
            name: "foo",
            typeName: TypeName(name: "(FooAlias, Int)", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple)
        )

        let types = """
        typealias FooAlias = Foo
        class Foo {}
        class Bar { func some(foo: (FooAlias, Int)) }
        """.parse()
        let methodParameter = types.first?.methods.first?.parameters.first
        let tupleElement = methodParameter?.typeName.tuple?.elements.first

        XCTAssertEqual(methodParameter, expectedMethodParameter)
        XCTAssertEqual(methodParameter?.actualTypeName, expectedMethodParameter.actualTypeName)
        XCTAssertEqual(tupleElement?.type, Class(name: "Foo"))
    }

    func test_typealiases_andMethodParameter_itReplacesMethodParameterAliasTypeWithActualTupleTypeName() {
        let expectedActualTypeName = TypeName(name: "(Foo, Int)")
        expectedActualTypeName.tuple = TupleType(name: "(Foo, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Foo"), type: Class(name: "Foo")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ])
        let expectedMethodParameter = MethodParameter(
            name: "foo",
            typeName: TypeName(name: "GlobalAlias", actualTypeName: expectedActualTypeName, tuple: expectedActualTypeName.tuple)
        )

        let types = "typealias GlobalAlias = (Foo, Int); class Foo {}; class Bar { func some(foo: GlobalAlias) }".parse()
        let methodParameter = types.first?.methods.first?.parameters.first

        XCTAssertEqual(methodParameter, expectedMethodParameter)
        XCTAssertEqual(methodParameter?.actualTypeName, expectedMethodParameter.actualTypeName)
        XCTAssertEqual(methodParameter?.typeName.isTuple, true)
    }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueTypeAliasWithActualType() {
        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"))

        let types = """
        typealias FooAlias = Foo
        class Foo {}
        enum Some { case optionA(FooAlias) }
        """.parse()
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

        let types = "typealias FooAlias = Foo; class Foo {}; enum Some { case optionA((FooAlias, Int)) }".parse()
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

        let types = "typealias GlobalAlias = (Foo, Int); class Foo {}; enum Some { case optionA(GlobalAlias) }".parse()
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

        let types = "typealias JSON = [String: Any]; enum Some { case optionA(JSON) }".parse()
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue?.typeName, expectedAssociatedValue.typeName)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
                        }

    func test_typealias_andAssociatedValue_itReplacesAssociatedValueAliasTypeWithActualArrayTypeName() {
        let expectedTypeName = TypeName(name: "[Any]")
        expectedTypeName.array = ArrayType(name: "[Any]", elementTypeName: TypeName(name: "Any"), elementType: nil)
        expectedTypeName.generic = GenericType(name: "Array", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "Any"), type: nil)])

        let expectedAssociatedValue = AssociatedValue(typeName: TypeName(name: "JSON", actualTypeName: expectedTypeName, array: expectedTypeName.array, generic: expectedTypeName.generic), type: nil)

        let types = "typealias JSON = [Any]; enum Some { case optionA(JSON) }".parse()
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

        let types = "typealias JSON = (String) -> Any; enum Some { case optionA(JSON) }".parse()
        let associatedValue = (types.last as? Enum)?.cases.first?.associatedValues.first

        XCTAssertEqual(associatedValue, expectedAssociatedValue)
        XCTAssertEqual(associatedValue?.actualTypeName, expectedAssociatedValue.actualTypeName)
    }

    func test_typealias_andVariable_itReplacesVariableAliasWithActualTypeViaThreeTypealiases() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FinalAlias", actualTypeName: TypeName(name: "Foo")), type: Class(name: "Foo"), definedInTypeName: TypeName(name: "Bar"))

        let type = """
        typealias FooAlias = Foo
        typealias BarAlias = FooAlias
        typealias FinalAlias = BarAlias
        class Foo {}
        class Bar { var foo: FinalAlias }
        """.parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_typealias_andVariable_itReplacesVariableOptionalAliasTypeWithActualType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "GlobalAlias?", actualTypeName: TypeName(name: "Foo?")), type: Class(name: "Foo"), definedInTypeName: TypeName(name: "Bar"))

        let type = "typealias GlobalAlias = Foo; class Foo {}; class Bar { var foo: GlobalAlias? }".parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_typealias_andVariable_itExtendsActualTypeWithTypeAliasExtension() {
        let types = "typealias GlobalAlias = Foo; class Foo: TestProtocol { }; extension GlobalAlias: AnotherProtocol {}".parse()
        XCTAssertEqual(types, [
            Class(
                name: "Foo",
                accessLevel: .internal,
                isExtension: false,
                variables: [],
                inheritedTypes: ["TestProtocol", "AnotherProtocol"]
            )
        ])
    }

    func test_typealias_andVariable_itUpdatesInheritedTypesWithRealTypeName() {
        let expectedFoo = Class(name: "Foo")
        let expectedClass = Class(name: "Bar", inheritedTypes: ["Foo"])
        expectedClass.inherits = ["Foo": expectedFoo]

        let types = "typealias GlobalAliasFoo = Foo; class Foo { }; class Bar: GlobalAliasFoo {}".parse()

        XCTAssertTrue(types.contains(expectedClass))
    }

    func test_typealias_andGlobalProtocolComposition_itReplacesVariableAliasTypeWithProtocolCompositionTypes() {
        let expectedProtocol1 = Protocol(name: "Foo")
        let expectedProtocol2 = Protocol(name: "Bar")
        let expectedProtocolComposition = ProtocolComposition(name: "GlobalComposition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])

        let type = "typealias GlobalComposition = Foo & Bar; protocol Foo {}; protocol Bar {}".parse().last as? ProtocolComposition

        XCTAssertEqual(type, expectedProtocolComposition)
        XCTAssertEqual(type?.composedTypes?.first, expectedProtocol1)
        XCTAssertEqual(type?.composedTypes?.last, expectedProtocol2)
    }

    func test_typealias_andGlobalProtocolComposition_itDeconstructsCompositionsOfProtocolsForImplements() {
        let expectedProtocol1 = Protocol(name: "Foo")
        let expectedProtocol2 = Protocol(name: "Bar")
        let expectedProtocolComposition = ProtocolComposition(name: "GlobalComposition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])

        let type = "typealias GlobalComposition = Foo & Bar; protocol Foo {}; protocol Bar {}; class Implements: GlobalComposition {}".parse().last as? Class

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

        let type = "typealias GlobalComposition = Foo & Bar; protocol Foo {}; class Bar {}; class Implements: GlobalComposition {}".parse().last as? Class

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

        let type = "class Bar { typealias FooAlias = Foo; var foo: FooAlias }; class Foo {}".parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itReplacesVariableAliasTypeWithActualContainedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "Bar.Foo")), type: Class(name: "Foo", parent: Class(name: "Bar")), definedInTypeName: TypeName(name: "Bar"))

        let type = "class Bar { typealias FooAlias = Foo; var foo: FooAlias; class Foo {} }".parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itReplacesVariableAliasTypeWithActualForeignContainedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "FooAlias", actualTypeName: TypeName(name: "FooBar.Foo")), type: Class(name: "Foo", parent: Type(name: "FooBar")), definedInTypeName: TypeName(name: "Bar"))

        let type = "class Bar { typealias FooAlias = FooBar.Foo; var foo: FooAlias }; class FooBar { class Foo {} }".parse().first
        let variable = type?.variables.first

        XCTAssertEqual(variable, expectedVariable)
        XCTAssertEqual(variable?.actualTypeName, expectedVariable.actualTypeName)
        XCTAssertEqual(variable?.type, expectedVariable.type)
    }

    func test_localTypealias_itPopulatesTheLocalCollectionOfTypealiases() {
        let expectedType = Class(name: "Foo")
        let expectedParent = Class(name: "Bar")
        let type = "class Bar { typealias FooAlias = Foo }; class Foo {}".parse().first
        let aliases = type?.typealiases

        XCTAssertEqual(aliases?.count, 1)
        XCTAssertEqual(aliases?["FooAlias"], Typealias(aliasName: "FooAlias", typeName: TypeName(name: "Foo"), parent: expectedParent))
        XCTAssertEqual(aliases?["FooAlias"]?.type, expectedType)
    }

    func test_localTypealias_itPopulatesTheGlobalCollectionOfTypealiases() {
        let expectedType = Class(name: "Foo")
        let expectedParent = Class(name: "Bar")
        let aliases = "class Bar { typealias FooAlias = Foo }; class Foo {}".parse(\.typealiases)

        XCTAssertEqual(aliases.count, 1)
        XCTAssertEqual(aliases.first, Typealias(aliasName: "FooAlias", typeName: TypeName(name: "Foo"), parent: expectedParent))
        XCTAssertEqual(aliases.first?.type, expectedType)
    }

    func test_globalTypealias_itExtractsTypealiasesOfOtherTypealiases() {
        XCTAssertEqual(
            "typealias Foo = Int; typealias Bar = Foo".parse(\.typealiases),
            [
                Typealias(aliasName: "Bar", typeName: TypeName(name: "Foo")),
                Typealias(aliasName: "Foo", typeName: TypeName(name: "Int"))
            ]
        )
    }

    func test_globalTypealias_itExtractsTypealiasesOfOtherTypealiasesOfAType() {
        XCTAssertEqual(
            "typealias Foo = Baz; typealias Bar = Foo; class Baz {}".parse(\.typealiases),
            [
                Typealias(aliasName: "Bar", typeName: TypeName(name: "Foo")),
                Typealias(aliasName: "Foo", typeName: TypeName(name: "Baz"))
            ]
        )
    }

    func test_globalTypealias_itResolvesTypesTransitively() {
        let expectedType = Class(name: "Baz")

        let typealiases = "typealias Foo = Bar; typealias Bar = Baz; class Baz {}".parse(\.typealiases)

        XCTAssertEqual(typealiases.count, 2)
        XCTAssertEqual(typealiases.first?.type, expectedType)
        XCTAssertEqual(typealiases.last?.type, expectedType)
    }

    func test_associatedValue_itExtractsType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))
        let item = Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])])

        let parsed = "protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar) }".parse()
        let parsedItem = parsed.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedItem, item)
        XCTAssertEqual(associatedValue.type, parsedItem?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsOptionalType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar?"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))
        let item = Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])])

        let parsed = "protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar?) }".parse()
        let parsedItem = parsed.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedItem, item)
        XCTAssertEqual(associatedValue.type, parsedItem?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsTypealias() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Bar2"), type: Class(name: "Bar", inheritedTypes: ["Baz"]))
        let item = Enum(name: "Foo", cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])])

        let parsed = "typealias Bar2 = Bar; protocol Baz {}; class Bar: Baz {}; enum Foo { case optionA(Bar2) }".parse()
        let parsedItem = parsed.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedItem, item)
        XCTAssertEqual(associatedValue.type, parsedItem?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedValue_itExtractsSameIndirectEnumType() {
        let associatedValue = AssociatedValue(typeName: TypeName(name: "Foo"))
        let item = Enum(name: "Foo", inheritedTypes: ["Baz"], cases: [EnumCase(name: "optionA", associatedValues: [associatedValue])], modifiers: [
            Modifier(name: "indirect")
        ])
        associatedValue.type = item

        let parsed = "protocol Baz {}; indirect enum Foo: Baz { case optionA(Foo) }".parse()
        let parsedItem = parsed.compactMap { $0 as? Enum }.first

        XCTAssertEqual(parsedItem, item)
        XCTAssertEqual(associatedValue.type, parsedItem?.cases.first?.associatedValues.first?.type)
    }

    func test_associatedType_itExtractsTypeWhenConstrainedToTypealias() {
        let code = """
        protocol Foo {
            typealias AEncodable = Encodable
            associatedtype Bar: AEncodable
        }
        """
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
        let actualProtocol = code.parse().first
        XCTAssertEqual(actualProtocol, expectedProtocol)
        let actualTypeName = (actualProtocol as? SourceryProtocol)?.associatedTypes.first?.value.typeName?.actualTypeName
        XCTAssertEqual(actualTypeName, givenTypealias.actualTypeName)
    }

    func test_nestedType_itExtractsDefinedInType() {
        let expectedMethod = Method(name: "some()", selectorName: "some", definedInTypeName: TypeName(name: "Foo.Bar"))

        let types = "class Foo { class Bar { func some() } }".parse()
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

        let types = """
        struct Blah {
            struct FooBar {}
            struct Foo<T> {}
            struct Bar {
                let foo: Foo<FooBar>?
            }
        }
        """.parse()
        let bar = types.first { $0.name == "Blah.Bar" }

        XCTAssertEqual(bar?.variables.first, expectedVariable)
        XCTAssertEqual(bar?.variables.first?.actualTypeName, expectedVariable.actualTypeName)
    }

    func test_nestedType_itExtractsPropertyOfNestedType() {
        let expectedVariable = Variable(name: "foo", typeName: TypeName(name: "Foo?", actualTypeName: TypeName(name: "Blah.Foo?")), accessLevel: (read: .internal, write: .none), definedInTypeName: TypeName(name: "Blah.Bar"))
        let expectedBlah = Struct(name: "Blah", containedTypes: [Struct(name: "Foo"), Struct(name: "Bar", variables: [expectedVariable])])

        let types = "struct Blah { struct Foo {}; struct Bar { let foo: Foo? }}".parse()
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

        let types = "struct Blah { struct Foo {}; struct Bar { let foo: [Foo]? }}".parse()
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

        let types = "struct Blah { struct Foo {}; struct Bar { let foo: [Foo: Foo]? }}".parse()
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

        let types = "struct Blah { struct Foo {}; struct Bar { let foo: (a: Foo, _: Foo, Foo)? }}".parse()
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

        let types = """
        struct RightType {}
        protocol GenericProtocol {
            associatedtype LeftType
        }
        protocol SomeGenericProtocol: GenericProtocol where LeftType == RightType {}
        """.parse()
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
        let functions = "func foo() -> Bar<String> { }".parse(\.1)
        XCTAssertEqual(functions[0], SourceryMethod(
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
        let functions = "func foo() -> (bar: String, biz: Int) { }".parse(\.functions)
        XCTAssertEqual(functions[0], SourceryMethod(
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

private extension String {
    func parse<T>(
        _ keyPath: KeyPath<(types: [Type], functions: [SourceryMethod], typealiases: [Typealias]), [T]> = \.types,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [T] {
        do {
            let parserResult = try FileParserSyntax(contents: self).parse()
            return Composer.uniqueTypesAndFunctions(parserResult)[keyPath: keyPath]
        } catch {
            XCTFail(String(describing: error), file: file, line: line)
            return []
        }
    }
}

private struct Module {
    let name: String?
    let content: String
}

private extension Array where Element == Module {
    func parse() -> (types: [Type], functions: [SourceryMethod], typealiases: [Typealias]) {
        let results = compactMap {
            try? FileParserSyntax(contents: $0.content, module: $0.name).parse()
        }

        let combinedResult = results.reduce(FileParserResult(path: nil, module: nil, types: [], functions: [], typealiases: [])) { acc, next in
            acc.typealiases += next.typealiases
            acc.types += next.types
            acc.functions += next.functions
            return acc
        }

        return Composer.uniqueTypesAndFunctions(combinedResult)
    }
}
