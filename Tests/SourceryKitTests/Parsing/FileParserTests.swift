import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class FileParserTests: XCTestCase {
    func test_doesNotCrashOnLocalizedStrings() throws {
        let templatePath = Stubs.errorsDirectory + Path("localized-error.swift")
        let content = try templatePath.read(.utf8)
        _ = content.parse()
    }

    func test_parsesAnnotationsFromExtensions() {
        let result = """
        // sourcery: forceMockPublisher
        public extension AnyPublisher {}
        """.parse()

        let annotations: [String: NSObject] = ["forceMockPublisher": NSNumber(value: true)]

        XCTAssertEqual(result.types.first?.annotations, annotations)
    }

    func test_parsesAnnotationBlock() {
        let annotations = [
            ["skipEquality": NSNumber(value: true)],
            ["skipEquality": NSNumber(value: true), "extraAnnotation": NSNumber(value: Float(2))],
            [:]
        ]
        let expectedVariables = (1 ... 3)
            .map { Variable(name: "property\($0)", typeName: TypeName(name: "Int"), annotations: annotations[$0 - 1], definedInTypeName: TypeName(name: "Foo")) }
        let expectedType = Class(name: "Foo", variables: expectedVariables, annotations: ["skipEquality": NSNumber(value: true)])

        let result = """
        // sourcery:begin: skipEquality
        class Foo {
            var property1: Int
            // sourcery: extraAnnotation = 2
            var property2: Int
            // sourcery:end
            var property3: Int
        }
        """.parse()

        XCTAssertEqual(result.types, [expectedType])
    }

    func test_parsesFileAnnotationBlock() {
        let annotations: [[String: NSObject]] = [
            ["fileAnnotation": NSNumber(value: true), "skipEquality": NSNumber(value: true)],
            ["fileAnnotation": NSNumber(value: true), "skipEquality": NSNumber(value: true), "extraAnnotation": NSNumber(value: Float(2))],
            ["fileAnnotation": NSNumber(value: true)]
        ]
        let expectedVariables = (1 ... 3)
            .map { Variable(name: "property\($0)", typeName: TypeName(name: "Int"), annotations: annotations[$0 - 1], definedInTypeName: TypeName(name: "Foo")) }
        let expectedType = Class(name: "Foo", variables: expectedVariables, annotations: ["fileAnnotation": NSNumber(value: true), "skipEquality": NSNumber(value: true)])

        let result = """
        // sourcery:file: fileAnnotation
        // sourcery:begin: skipEquality

        class Foo {
            var property1: Int

            // sourcery: extraAnnotation = 2
            var property2: Int

            // sourcery:end
            var property3: Int
        }
        """.parse()

        XCTAssertEqual(result.types.first, expectedType)
    }

    func test_struct_parsesStruct() {
        XCTAssertEqual("struct Foo { }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [])
        ])
    }

    func test_struct_parsesImport() {
        let expectedStruct = Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [])
        expectedStruct.imports = [
            Import(path: "SimpleModule"),
            Import(path: "SpecificModule.ClassName")
        ]

        XCTAssertEqual("""
        import SimpleModule
        import SpecificModule.ClassName
        struct Foo {}
        """.parse().types.first, expectedStruct)
    }

    func test_struct_parsesStructVisibility() {
        XCTAssertEqual("public struct Foo { }".parse().types, [
            Struct(name: "Foo", accessLevel: .public, isExtension: false, variables: [], modifiers: [Modifier(name: "public")])
        ])
    }

    func test_struct_parsesStructVisibilityForExtendedTypesViaExtension() {
        let foo = Struct(name: "Foo", accessLevel: .public, isExtension: false, variables: [], modifiers: [Modifier(name: "public")])

        XCTAssertEqual("""
        public struct Foo { }
        public extension Foo {
            struct Boo {}
        }
        """.parse().types.last, Struct(name: "Boo", parent: foo, accessLevel: .public, isExtension: false, variables: [], modifiers: []))
    }

    func test_struct_parsesGenericStruct() {
        XCTAssertEqual("struct Foo<Something> { }".parse().types, [Struct(name: "Foo", isGeneric: true)])
    }

    func test_struct_parsesInstanceVariables() {
        XCTAssertEqual("struct Foo { var x: Int }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [Variable(name: "x", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: false, definedInTypeName: TypeName(name: "Foo"))])
        ])
    }

    func test_struct_parsesInstanceVariablesWithCustomAccessors() {
        XCTAssertEqual("struct Foo { public private(set) var x: Int }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(
                    name: "x",
                    typeName: TypeName(name: "Int"),
                    accessLevel: (read: .public, write: .private),
                    isComputed: false,
                    modifiers: [
                        Modifier(name: "public"),
                        Modifier(name: "private", detail: "set")
                    ],
                    definedInTypeName: TypeName(name: "Foo")
                )
            ])
        ])
    }

    func test_struct_parsesMultilineInstanceVariablesDefinitions() {
        let defaultValue = """
        [
            "This isn't the simplest to parse",
            // Especially with interleaved comments
            "but we can deal with it",
            // pretty well
            "or so we hope"
        ]
        """

        XCTAssertEqual("""
        struct Foo {
            var complicatedArray = \(defaultValue)
        }
        """.parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(
                    name: "complicatedArray",
                    typeName: TypeName(
                        name: "[String]",
                        array: ArrayType(name: "[String]", elementTypeName: TypeName(name: "String")),
                        generic: GenericType(name: "Array", typeParameters: [.init(typeName: TypeName(name: "String"))])
                    ),
                    accessLevel: (read: .internal, write: .internal),
                    isComputed: false,
                    defaultValue: defaultValue,
                    definedInTypeName: TypeName(name: "Foo")
                )
            ])
        ])
    }

    func test_struct_parsesInstanceVariablesWithPropertySetters() {
        XCTAssertEqual("""
        struct Foo {
            var array = [Int]() {
                willSet {
                    print("new value \\(newValue)")
                }
            }
        }
        """.parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(
                    name: "array",
                    typeName: TypeName(
                        name: "[Int]",
                        array: ArrayType(name: "[Int]", elementTypeName: TypeName(name: "Int")),
                        generic: GenericType(name: "Array", typeParameters: [.init(typeName: TypeName(name: "Int"))])
                    ),
                    accessLevel: (read: .internal, write: .internal),
                    isComputed: false,
                    defaultValue: "[Int]()",
                    definedInTypeName: TypeName(name: "Foo")
                )
            ])
        ])
    }

    func test_struct_parsesComputedVariables() {
        XCTAssertEqual("struct Foo { var x: Int { return 2 } }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(name: "x", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .none), isComputed: true, isStatic: false, definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_struct_parsesClassVariables() {
        XCTAssertEqual("struct Foo { static var x: Int { return 2 }; class var y: Int = 0 }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(
                    name: "x",
                    typeName: TypeName(name: "Int"),
                    accessLevel: (read: .internal, write: .none),
                    isComputed: true,
                    isStatic: true,
                    modifiers: [
                        Modifier(name: "static")
                    ],
                    definedInTypeName: TypeName(name: "Foo")
                ),
                Variable(
                    name: "y",
                    typeName: TypeName(name: "Int"),
                    accessLevel: (read: .internal, write: .internal),
                    isComputed: false,
                    isStatic: true,
                    defaultValue: "0",
                    modifiers: [
                        Modifier(name: "class")
                    ],
                    definedInTypeName: TypeName(name: "Foo")
                )
            ])
        ])
    }

    func test_parsesNestedStruct() {
        let innerType = Struct(name: "Bar", accessLevel: .internal, isExtension: false, variables: [])

        XCTAssertEqual("struct Foo { struct Bar { } }".parse().types, [
            Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], containedTypes: [innerType]),
            innerType
        ])
    }

    func test_class_parsesVariables() {
        XCTAssertEqual("class Foo { var x: Int }".parse().types, [
            Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [
                Variable(name: "x", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: false, definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_class_parsesInheritedTypes() {
        XCTAssertEqual(
            "class Foo: TestProtocol, AnotherProtocol {}".parse().types.first(where: { $0.name == "Foo" }),
            Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol", "AnotherProtocol"])
        )
    }

    func test_class_parsesAnnotations() {
        let expectedType = Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol"])
        expectedType.annotations["firstLine"] = NSNumber(value: true)
        expectedType.annotations["thirdLine"] = NSNumber(value: 4543)

        XCTAssertEqual("// sourcery: thirdLine = 4543\n/// comment\n// sourcery: firstLine\nclass Foo: TestProtocol { }".parse().types, [expectedType])
    }

    func test_class_parsesDocumentation() {
        let expectedType = Class(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol"])
        expectedType.annotations["thirdLine"] = NSNumber(value: 4543)
        expectedType.documentation = ["doc", "comment", "baz"]

        XCTAssertEqual(
            "/// doc\n// sourcery: thirdLine = 4543\n/// comment\n// firstLine\n///baz\nclass Foo: TestProtocol { }".parse(parseDocumentation: true).types,
            [expectedType]
        )
    }

    func test_parsesTypealias() {
        XCTAssertEqual("typealias GlobalAlias = Foo; class Foo { typealias FooAlias = Int; class Bar { typealias BarAlias = Int } }".parse().typealiases, [
            Typealias(aliasName: "GlobalAlias", typeName: TypeName(name: "Foo"))
        ])
    }

    func test_parsesTypealiasForInnerType() {
        XCTAssertEqual("typealias GlobalAlias = Foo.Bar;".parse().typealiases, [
            Typealias(aliasName: "GlobalAlias", typeName: TypeName(name: "Foo.Bar"))
        ])
    }

    func test_parsesTypealiasOfAnotherTypealias() {
        XCTAssertEqual("typealias Foo = Int; typealias Bar = Foo".parse().typealiases, [
            Typealias(aliasName: "Foo", typeName: TypeName(name: "Int")),
            Typealias(aliasName: "Bar", typeName: TypeName(name: "Foo"))
        ])
    }

    func test_parsesTypealiasForTuple() {
        XCTAssertEqual("typealias GlobalAlias = (Foo, Bar)".parse().typealiases.first, Typealias(
            aliasName: "GlobalAlias",
            typeName: TypeName(name: "(Foo, Bar)", tuple: TupleType(name: "(Foo, Bar)", elements: [.init(name: "0", typeName: .init("Foo")), .init(name: "1", typeName: .init("Bar"))]))
        ))
    }

    func test_parsesTypealiasForClosure() {
        XCTAssertEqual("typealias GlobalAlias = (Int) -> (String)".parse().typealiases, [
            Typealias(aliasName: "GlobalAlias", typeName: TypeName(name: "(Int) -> String", closure: ClosureType(name: "(Int) -> String", parameters: [.init(typeName: TypeName(name: "Int"))], returnTypeName: TypeName(name: "String"))))
        ])
    }

    func test_parsesTypealiasForVoidClosure() {
        let parsed = "typealias GlobalAlias = () -> ()".parse().typealiases.first
        let expected = Typealias(aliasName: "GlobalAlias", typeName: TypeName(name: "() -> ()", closure: ClosureType(name: "() -> ()", parameters: [], returnTypeName: TypeName(name: "()"))))

        XCTAssertEqual(parsed, expected)
    }

    func test_parsesPrivateTypealias() {
        XCTAssertEqual("private typealias GlobalAlias = () -> ()".parse().typealiases, [
            Typealias(aliasName: "GlobalAlias", typeName: TypeName(name: "() -> ()", closure: ClosureType(name: "() -> ()", parameters: [], returnTypeName: TypeName(name: "()"))), accessLevel: .private)
        ])
    }

    func test_parsesNestedTypealias() {
        let foo = Type(name: "Foo")
        let bar = Type(name: "Bar", parent: foo)
        let fooBar = Type(name: "FooBar", parent: bar)

        let types = "class Foo { typealias FooAlias = String; struct Bar { typealias BarAlias = Int; struct FooBar { typealias FooBarAlias = Float } } }".parse().types

        let fooAliases = types.first?.typealiases
        let barAliases = types.first?.containedTypes.first?.typealiases
        let fooBarAliases = types.first?.containedTypes.first?.containedTypes.first?.typealiases

        XCTAssertEqual(fooAliases, ["FooAlias": Typealias(aliasName: "FooAlias", typeName: TypeName(name: "String"), parent: foo)])
        XCTAssertEqual(barAliases, ["BarAlias": Typealias(aliasName: "BarAlias", typeName: TypeName(name: "Int"), parent: bar)])
        XCTAssertEqual(fooBarAliases, ["FooBarAlias": Typealias(aliasName: "FooBarAlias", typeName: TypeName(name: "Float"), parent: fooBar)])
    }

    func test_protocolComposition_parsesReturnType() {
        let expectedFoo = Method(name: "foo()", selectorName: "foo", returnTypeName: TypeName(name: "ProtocolA & ProtocolB", isProtocolComposition: true), definedInTypeName: TypeName(name: "Foo"))
        expectedFoo.returnType = ProtocolComposition(name: "ProtocolA & Protocol B")
        let expectedFooOptional = Method(name: "fooOptional()", selectorName: "fooOptional", returnTypeName: TypeName(name: "(ProtocolA & ProtocolB)", isOptional: true, isProtocolComposition: true), definedInTypeName: TypeName(name: "Foo"))
        expectedFooOptional.returnType = ProtocolComposition(name: "ProtocolA & Protocol B")

        let methods = """
        protocol Foo {
            func foo() -> ProtocolA & ProtocolB
            func fooOptional() -> (ProtocolA & ProtocolB)?
        }
        """.parse().types[0].methods

        XCTAssertEqual(methods[0], expectedFoo)
        XCTAssertEqual(methods[1], expectedFooOptional)
    }

    func test_protocolComposition_parsesTypealias() {
        XCTAssertTrue("typealias Composition = Foo & Bar; protocol Foo {}; protocol Bar {}".parse().types.contains(
            ProtocolComposition(name: "Composition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])
        ))

        XCTAssertTrue("private typealias Composition = Foo & Bar; protocol Foo {}; protocol Bar {}".parse().types.contains(
            ProtocolComposition(name: "Composition", accessLevel: .private, inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])
        ))
    }

    func test_protocolComposition_parsesTypealias_whenThreeProtocols() {
        XCTAssertTrue("typealias Composition = Foo & Bar & Baz; protocol Foo {}; protocol Bar {}; protocol Baz {}".parse().types.contains(
            ProtocolComposition(name: "Composition", inheritedTypes: ["Foo", "Bar", "Baz"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar"), TypeName(name: "Baz")])
        ))
    }

    func test_protocolComposition_parsesTypealias_whenProtocolAndClass() {
        XCTAssertTrue("typealias Composition = Foo & Bar; protocol Foo {}; class Bar {}".parse().types.contains(
            ProtocolComposition(name: "Composition", inheritedTypes: ["Foo", "Bar"], composedTypeNames: [TypeName(name: "Foo"), TypeName(name: "Bar")])
        ))
    }

    func test_parsesLocalProtocolComposition() {
        let foo = Type(name: "Foo")
        let bar = Type(name: "Bar", parent: foo)

        let types = "protocol P {}; class Foo { typealias FooComposition = Bar & P; class Bar { typealias BarComposition = FooBar & P; class FooBar {} } }".parse().types

        let fooType = types.first(where: { $0.name == "Foo" })
        let fooComposition = fooType?.containedTypes.first
        let barComposition = fooType?.containedTypes.last?.containedTypes.first

        XCTAssertEqual(fooComposition, ProtocolComposition(name: "FooComposition", parent: foo, inheritedTypes: ["Bar", "P"], composedTypeNames: [TypeName(name: "Bar"), TypeName(name: "P")]))
        XCTAssertEqual(barComposition, ProtocolComposition(name: "BarComposition", parent: bar, inheritedTypes: ["FooBar", "P"], composedTypeNames: [TypeName(name: "FooBar"), TypeName(name: "P")]))
    }

    func test_enum_parsesEmptyEnum() {
        XCTAssertEqual("enum Foo { }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [])
        ])
    }

    func test_enum_parsesCases() {
        XCTAssertEqual("enum Foo { case optionA; case optionB }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [EnumCase(name: "optionA"), EnumCase(name: "optionB")])
        ])
    }

    func test_enum_parsesCasesWithSpecialNames() {
        XCTAssertEqual("""
        enum Foo {
            case `default`
            case `for`(something: Int, else: Float, `default`: Bool)
        }
        """.parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "`default`"),
                EnumCase(name: "`for`", associatedValues: [
                    AssociatedValue(name: "something", typeName: TypeName(name: "Int")),
                    AssociatedValue(name: "else", typeName: TypeName(name: "Float")),
                    AssociatedValue(name: "`default`", typeName: TypeName(name: "Bool"))
                ])
            ])
        ])
    }

    func test_enum_parsesMultibyteCases() {
        XCTAssertEqual("enum JapaneseEnum {\ncase アイウエオ\n}".parse().types, [
            Enum(name: "JapaneseEnum", cases: [EnumCase(name: "アイウエオ")])
        ])
    }

    func test_enum_parsesCasesWithAnnotations() {
        XCTAssertEqual("""
        enum Foo {
            // sourcery:begin: block
            // sourcery: first, second=\"value\"
            case optionA(/* sourcery: first, second = \"value\" */Int)
            // sourcery: third
            case optionB
            case optionC
            // sourcery:end
        }
        """.parse().types, [
            Enum(name: "Foo", cases: [
                EnumCase(name: "optionA", associatedValues: [
                    AssociatedValue(name: nil, typeName: TypeName(name: "Int"), annotations: [
                        "first": NSNumber(value: true),
                        "second": "value" as NSString,
                        "block": NSNumber(value: true)
                    ])
                ], annotations: [
                    "block": NSNumber(value: true),
                    "first": NSNumber(value: true),
                    "second": "value" as NSString
                ]),
                EnumCase(name: "optionB", annotations: [
                    "block": NSNumber(value: true),
                    "third": NSNumber(value: true)
                ]),
                EnumCase(name: "optionC", annotations: [
                    "block": NSNumber(value: true)
                ])
            ])
        ])
    }

    func test_enum_parsesCasesWithInlineAnnotations() {
        XCTAssertEqual(
            """
            enum Foo {
                //sourcery:begin: block
                /* sourcery: first, second = \"value\" */ case optionA(/* sourcery: first, second = \"value\" */Int);
                /* sourcery: third */ case optionB
                case optionC
                //sourcery:end
            }
            """.parse().types.first,
            Enum(
                name: "Foo",
                cases: [
                    EnumCase(name: "optionA", associatedValues: [
                        AssociatedValue(name: nil, typeName: TypeName(name: "Int"), annotations: [
                            "first": NSNumber(value: true),
                            "second": "value" as NSString,
                            "block": NSNumber(value: true)
                        ])
                    ], annotations: [
                        "block": NSNumber(value: true),
                        "first": NSNumber(value: true),
                        "second": "value" as NSString
                    ]),
                    EnumCase(name: "optionB", annotations: [
                        "block": NSNumber(value: true),
                        "third": NSNumber(value: true)
                    ]),
                    EnumCase(name: "optionC", annotations: [
                        "block": NSNumber(value: true)
                    ])
                ]
            )
        )
    }

    func test_enum_parsesOneLineCasesWithInlineAnnotations() {
        XCTAssertEqual(
            """
            enum Foo {
                //sourcery:begin: block
                case /* sourcery: first, second = \"value\" */ optionA(Int), /* sourcery: third, fourth = \"value\" */ optionB, optionC
                //sourcery:end
            }
            """.parse().types.first,
            Enum(
                name: "Foo",
                cases: [
                    EnumCase(name: "optionA", associatedValues: [
                        AssociatedValue(name: nil, typeName: TypeName(name: "Int"), annotations: [
                            "block": NSNumber(value: true)
                        ])
                    ], annotations: [
                        "block": NSNumber(value: true),
                        "first": NSNumber(value: true),
                        "second": "value" as NSString
                    ]),
                    EnumCase(name: "optionB", annotations: [
                        "block": NSNumber(value: true),
                        "third": NSNumber(value: true),
                        "fourth": "value" as NSString
                    ]),
                    EnumCase(name: "optionC", annotations: [
                        "block": NSNumber(value: true)
                    ])
                ]
            )
        )
    }

    func test_enum_parsesCasesWithAnnotationsAndComputedVariables() {
        XCTAssertEqual(
            """
            enum Foo {
                // sourcery: var
                var first: Int { return 0 }
                // sourcery: first, second=\"value\"
                case optionA(Int)
                // sourcery: var
                var second: Int { return 0 }
                // sourcery: third
                case optionB
                case optionC
            }
            """.parse().types.first,
            Enum(
                name: "Foo",
                cases: [
                    EnumCase(name: "optionA", associatedValues: [
                        AssociatedValue(name: nil, typeName: TypeName(name: "Int"))
                    ], annotations: [
                        "first": NSNumber(value: true),
                        "second": "value" as NSString
                    ]),
                    EnumCase(name: "optionB", annotations: [
                        "third": NSNumber(value: true)
                    ]),
                    EnumCase(name: "optionC")
                ], variables: [
                    Variable(name: "first", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: true, annotations: ["var": NSNumber(value: true)], definedInTypeName: TypeName(name: "Foo")),
                    Variable(name: "second", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: true, annotations: ["var": NSNumber(value: true)], definedInTypeName: TypeName(name: "Foo"))
                ]
            )
        )
    }

    func test_enum_parsesAssociatedValueAnnotations() {
        let result = """
        enum Foo {
            case optionA(
                // sourcery: first
                // sourcery: second, third = "value"
                Int)
            case optionB
        }
        """.parse()
        XCTAssertEqual(result.types, [
            Enum(
                name: "Foo",
                cases: [
                    EnumCase(name: "optionA", associatedValues: [
                        AssociatedValue(name: nil, typeName: TypeName(name: "Int"), annotations: ["first": NSNumber(value: true), "second": NSNumber(value: true), "third": "value" as NSString])
                    ]),
                    EnumCase(name: "optionB")
                ]
            )
        ])
    }

    func test_enum_parsesAssociatedValueInlineAnnotations() {
        let result = "enum Foo {\n case optionA(/* sourcery: annotation*/Int)\n case optionB }".parse()
        XCTAssertEqual(result.types, [
            Enum(
                name: "Foo",
                cases: [
                    EnumCase(name: "optionA", associatedValues: [
                        AssociatedValue(name: nil, typeName: TypeName(name: "Int"), annotations: ["annotation": NSNumber(value: true)])
                    ]),
                    EnumCase(name: "optionB")
                ]
            )
        ])
    }

    func test_enum_parsesVariables() {
        XCTAssertEqual("enum Foo { var x: Int { return 1 } }".parse().types, [
            Enum(
                name: "Foo",
                accessLevel: .internal,
                isExtension: false,
                inheritedTypes: [],
                cases: [],
                variables: [Variable(name: "x", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: true, definedInTypeName: TypeName(name: "Foo"))]
            )
        ])
    }

    func test_enum_parsesInheritedType() {
        XCTAssertEqual("enum Foo: SomeProtocol { case optionA }; protocol SomeProtocol {}".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["SomeProtocol"], rawTypeName: nil, cases: [EnumCase(name: "optionA")]),
            Protocol(name: "SomeProtocol")
        ])
    }

    func test_enum_parsesEnumsWithCustomValues() {
        XCTAssertEqual("""
        enum Foo: String {
            case optionA = "Value"
        }
        """.parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "optionA", rawValue: "Value")])
        ])

        XCTAssertEqual("""
        enum Foo: Int {
            case optionA = 2
        }
        """.parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["Int"], cases: [EnumCase(name: "optionA", rawValue: "2")])
        ])

        XCTAssertEqual("""
        enum Foo: Int {
            case optionA = -1
            case optionB = 0
        }
        """.parse().types, [
            Enum(
                name: "Foo",
                accessLevel: .internal,
                isExtension: false,
                inheritedTypes: ["Int"],
                cases: [
                    EnumCase(name: "optionA", rawValue: "-1"),
                    EnumCase(name: "optionB", rawValue: "0")
                ]
            )
        ])
    }

    func test_enum_parsesEnumsWithoutRawType() {
        let expectedEnum = Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [EnumCase(name: "optionA")])

        XCTAssertEqual("enum Foo { case optionA }".parse().types, [expectedEnum])
    }

    func test_enum_parsesEnumsWithAssociatedTypes() {
        XCTAssertEqual("enum Foo { case optionA(Observable<Int, Int>); case optionB(Int, named: Float, _: Int); case optionC(dict: [String: String]) }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "optionA", associatedValues: [
                    AssociatedValue(localName: nil, externalName: nil, typeName: TypeName(name: "Observable<Int, Int>", generic: GenericType(
                        name: "Observable", typeParameters: [
                            GenericTypeParameter(typeName: TypeName(name: "Int")),
                            GenericTypeParameter(typeName: TypeName(name: "Int"))
                        ])))
                ]),
                EnumCase(name: "optionB", associatedValues: [
                    AssociatedValue(localName: nil, externalName: "0", typeName: TypeName(name: "Int")),
                    AssociatedValue(localName: "named", externalName: "named", typeName: TypeName(name: "Float")),
                    AssociatedValue(localName: nil, externalName: "2", typeName: TypeName(name: "Int"))
                ]),
                EnumCase(name: "optionC", associatedValues: [
                    AssociatedValue(localName: "dict", externalName: nil, typeName: TypeName(name: "[String: String]", dictionary: DictionaryType(name: "[String: String]", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "String")), generic: GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String")), GenericTypeParameter(typeName: TypeName(name: "String"))])))
                ])
            ])
        ])
    }

    func test_enum_parsesEnumsWithIndirectCases() {
        XCTAssertEqual("enum Foo { case optionA; case optionB; indirect case optionC(Foo) }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "optionA", indirect: false),
                EnumCase(name: "optionB"),
                EnumCase(name: "optionC", associatedValues: [AssociatedValue(typeName: TypeName(name: "Foo"))], indirect: true)
            ])
        ])
        XCTAssertEqual("""
        enum Foo {
            /// Option A
            case optionA
            /// Option B
            case optionB
            /// Option C
            indirect case optionC(Foo)
        }
        """.parse(parseDocumentation: true).types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "optionA", documentation: ["Option A"], indirect: false),
                EnumCase(name: "optionB", documentation: ["Option B"]),
                EnumCase(name: "optionC", associatedValues: [AssociatedValue(typeName: TypeName(name: "Foo"))], documentation: ["Option C"], indirect: true)
            ])
        ])
    }

    func test_enum_parsesEnumsWithVoidAssociatedType() {
        XCTAssertEqual("enum Foo { case optionA(Void); case optionB(Void) }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "optionA", associatedValues: [AssociatedValue(typeName: TypeName(name: "Void"))]),
                EnumCase(name: "optionB", associatedValues: [AssociatedValue(typeName: TypeName(name: "Void"))])
            ])
        ])
    }

    func test_enum_parsesDefaultValuesForAssociatedValues() {
        XCTAssertEqual("enum Foo { case optionA(Int = 1, named: Float = 42.0, _: Bool = false); case optionB(Bool = true) }".parse().types, [
            Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [
                EnumCase(name: "optionA", associatedValues: [
                    AssociatedValue(localName: nil, externalName: "0", typeName: TypeName(name: "Int"), defaultValue: "1"),
                    AssociatedValue(localName: "named", externalName: "named", typeName: TypeName(name: "Float"), defaultValue: "42.0"),
                    AssociatedValue(localName: nil, externalName: "2", typeName: TypeName(name: "Bool"), defaultValue: "false")
                ]),
                EnumCase(name: "optionB", associatedValues: [
                    AssociatedValue(localName: nil, externalName: nil, typeName: TypeName(name: "Bool"), defaultValue: "true")
                ])
            ])
        ])
    }

    func test_protocol_genericRequirements() {
        XCTAssertEqual("""
        protocol SomeGenericProtocol: GenericProtocol {}
        """.parse().types.first, Protocol(name: "SomeGenericProtocol", inheritedTypes: ["GenericProtocol"]))

        XCTAssertEqual(
            """
            protocol SomeGenericProtocol: GenericProtocol where LeftType == RightType {}
            """.parse().types.first,
            Protocol(
                name: "SomeGenericProtocol",
                inheritedTypes: ["GenericProtocol"],
                genericRequirements: [
                    GenericRequirement(leftType: .init(name: "LeftType"), rightType: .init(typeName: .init("RightType")), relationship: .equals)
                ]
            )
        )

        XCTAssertEqual(
            """
            protocol SomeGenericProtocol: GenericProtocol where LeftType: RightType {}
            """.parse().types.first,
            Protocol(
                name: "SomeGenericProtocol",
                inheritedTypes: ["GenericProtocol"],
                genericRequirements: [
                    GenericRequirement(leftType: .init(name: "LeftType"), rightType: .init(typeName: .init("RightType")), relationship: .conformsTo)
                ]
            )
        )

        XCTAssertEqual(
            """
            protocol SomeGenericProtocol: GenericProtocol where LeftType == RightType, LeftType2: RightType2 {}
            """.parse().types.first,
            Protocol(
                name: "SomeGenericProtocol",
                inheritedTypes: ["GenericProtocol"],
                genericRequirements: [
                    GenericRequirement(leftType: .init(name: "LeftType"), rightType: .init(typeName: .init("RightType")), relationship: .equals),
                    GenericRequirement(leftType: .init(name: "LeftType2"), rightType: .init(typeName: .init("RightType2")), relationship: .conformsTo)
                ]
            )
        )
    }

    func test_protocol_emptyProtocol() {
        XCTAssertEqual("protocol Foo { }".parse().types, [Protocol(name: "Foo")])
    }

    func test_protocol_doesNotConsiderProtocolVariablesAsComputed() {
        XCTAssertEqual("protocol Foo { var some: Int { get } }".parse().types, [
            Protocol(name: "Foo", variables: [Variable(name: "some", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: false, definedInTypeName: TypeName(name: "Foo"))])
        ])
    }

    func test_protocol_doesConsiderTypeVariablesAsComputedWhenTheyAreEvenIfTheyAdhereToProtocol() {
        XCTAssertEqual(
            "protocol Foo { var some: Int { get }\nvar some2: Int { get } }\nclass Bar: Foo { var some: Int { return 2 }\nvar some2: Int { get { return 2 } } }"
                .parse().types.first(where: { $0.name == "Bar" }),
            Class(
                name: "Bar", variables: [
                    Variable(name: "some", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: true, definedInTypeName: TypeName(name: "Bar")),
                    Variable(name: "some2", typeName: TypeName(name: "Int"), accessLevel: (.internal, .none), isComputed: true, definedInTypeName: TypeName(name: "Bar"))
                ],
                inheritedTypes: ["Foo"]
            )
        )
    }

    func test_protocol_doesNotConsiderTypeVariablesAsComputedWhenTheyAreNotEvenIfTheyAdhereToProtocolAndHaveDidSetBlocks() {
        XCTAssertEqual(
            "protocol Foo { var some: Int { get } }\nclass Bar: Foo { var some: Int { didSet { } }".parse().types.first(where: { $0.name == "Bar" }),
            Class(
                name: "Bar",
                variables: [Variable(name: "some", typeName: TypeName(name: "Int"), accessLevel: (.internal, .internal), isComputed: false, definedInTypeName: TypeName(name: "Bar"))],
                inheritedTypes: ["Foo"]
            )
        )
    }

    func test_protocol_setsMemberAccessLevelToProtocolAccessLevel() {
        func assert(_ accessLevel: AccessLevel, line: UInt = #line) {
            XCTAssertEqual("\(accessLevel) protocol Foo { var some: Int { get }; func foo() -> Void }".parse().types, [
                Protocol(name: "Foo", accessLevel: accessLevel, variables: [Variable(name: "some", typeName: TypeName(name: "Int"), accessLevel: (accessLevel, .none), isComputed: false, definedInTypeName: TypeName(name: "Foo"))], methods: [Method(name: "foo()", selectorName: "foo", returnTypeName: TypeName(name: "Void"), throws: false, rethrows: false, accessLevel: accessLevel, definedInTypeName: TypeName(name: "Foo"))], modifiers: [Modifier(name: "\(accessLevel)")])
            ], line: line)
        }

        assert(.private)
        assert(.internal)
        assert(.private)
    }
}

private extension String {
    func parse(parseDocumentation: Bool = false) -> FileParserResult {
        do {
            return try makeParser(for: self, parseDocumentation: parseDocumentation).parse()
        } catch {
            XCTFail(String(describing: error))
            return .init(path: nil, module: nil, types: [], functions: [])
        }
    }
}
