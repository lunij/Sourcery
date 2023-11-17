import Foundation
import PathKit
import XCTest
@testable import SourceryKit

class Bar {}

class SwiftSyntaxParserFunctionTests: XCTestCase {
    func test_parsesMethodsWithInoutProperties() {
        let methods = """
        class Foo {
            func fooInOut(some: Int, anotherSome: inout String)
        }
        """.parse()[0].methods

        XCTAssertEqual(methods[0], Function(name: "fooInOut(some: Int, anotherSome: inout String)", selectorName: "fooInOut(some:anotherSome:)", parameters: [
            FunctionParameter(name: "some", typeName: TypeName(name: "Int")),
            FunctionParameter(name: "anotherSome", typeName: TypeName(name: "inout String"), isInout: true)
        ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo")))
    }

    func test_parsesMethodsWithInoutClosure() {
        let method = """
        class Foo {
            func fooInOut(some: Int, anotherSome: (inout String) -> Void)
        }
        """.parse()[0].methods.first

        XCTAssertEqual(method, Function(name: "fooInOut(some: Int, anotherSome: (inout String) -> Void)", selectorName: "fooInOut(some:anotherSome:)", parameters: [
            FunctionParameter(name: "some", typeName: TypeName(name: "Int")),
            FunctionParameter(name: "anotherSome", typeName: TypeName.buildClosure(ClosureParameter(typeName: TypeName.String, isInout: true), returnTypeName: .Void))
        ], returnTypeName: .Void, definedInTypeName: TypeName(name: "Foo")))
    }

    func test_parsesMethodsWithAsyncClosure() {
        let method = """
        class Foo {
            func fooAsync(some: Int, anotherSome: (String) async -> Void)
        }
        """.parse()[0].methods.first

        XCTAssertEqual(method, Function(name: "fooAsync(some: Int, anotherSome: (String) async -> Void)", selectorName: "fooAsync(some:anotherSome:)", parameters: [
            FunctionParameter(name: "some", typeName: TypeName(name: "Int")),
            FunctionParameter(name: "anotherSome", typeName: TypeName(name: "(String) async -> Void", closure: ClosureType(name: "(String) async -> Void", parameters: [ClosureParameter(typeName: TypeName(name: "String"))], returnTypeName: .Void, asyncKeyword: "async")))
        ], returnTypeName: .Void, definedInTypeName: TypeName(name: "Foo")))
    }

    func test_parsesMethodsWithAttributes() {
        let methods = """
        class Foo {
        @discardableResult func foo() ->
                                    Foo
        }
        """.parse()[0].methods

        XCTAssertEqual(methods[0], Function(name: "foo()", selectorName: "foo", returnTypeName: TypeName(name: "Foo"), attributes: ["discardableResult": [Attribute(name: "discardableResult")]], definedInTypeName: TypeName(name: "Foo")))
    }

    func test_parsesMethodsWithEscapingClosureAttribute() {
        let methods = """
        protocol ClosureProtocol {
            func setClosure(_ closure: @escaping () -> Void)
        }
        """.parse()[0].methods

        XCTAssertEqual(methods[0], Function(
            name: "setClosure(_ closure: @escaping () -> Void)",
            selectorName: "setClosure(_:)",
            parameters: [
                FunctionParameter(argumentLabel: nil, name: "closure", typeName: .buildClosure(TypeName(name: "Void"), attributes: ["escaping": [Attribute(name: "escaping")]]), type: nil, defaultValue: nil, annotations: [:], isInout: false)
            ],
            returnTypeName: TypeName(name: "Void"),
            attributes: [:],
            definedInTypeName: TypeName(name: "ClosureProtocol")
        ))
    }

    func test_parsesProtocolMethods() {
        let methods = """
        protocol Foo {
            init() throws; func bar(some: Int) throws ->Bar
            @discardableResult func foo() ->
                                        Foo
            func fooBar() rethrows ; func fooVoid();
            func fooAsync() async; func barAsync() async throws;
            func fooInOut(some: Int, anotherSome: inout String) }
        """.parse()[0].methods
        XCTAssertEqual(methods[0], Function(name: "init()", selectorName: "init", parameters: [], returnTypeName: TypeName(name: "Foo"), throws: true, isStatic: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[1], Function(name: "bar(some: Int)", selectorName: "bar(some:)", parameters: [
            FunctionParameter(name: "some", typeName: TypeName(name: "Int"))
        ], returnTypeName: TypeName(name: "Bar"), throws: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[2], Function(name: "foo()", selectorName: "foo", returnTypeName: TypeName(name: "Foo"), attributes: ["discardableResult": [Attribute(name: "discardableResult")]], definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[3], Function(name: "fooBar()", selectorName: "fooBar", returnTypeName: TypeName(name: "Void"), throws: false, rethrows: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[4], Function(name: "fooVoid()", selectorName: "fooVoid", returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[5], Function(name: "fooAsync()", selectorName: "fooAsync", returnTypeName: TypeName(name: "Void"), isAsync: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[6], Function(name: "barAsync()", selectorName: "barAsync", returnTypeName: TypeName(name: "Void"), isAsync: true, throws: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertEqual(methods[7], Function(name: "fooInOut(some: Int, anotherSome: inout String)", selectorName: "fooInOut(some:anotherSome:)", parameters: [
            FunctionParameter(name: "some", typeName: TypeName(name: "Int")),
            FunctionParameter(name: "anotherSome", typeName: TypeName(name: "inout String"), isInout: true)
        ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo")))
    }

    func test_parsesClassFunction() {
        XCTAssertEqual("class Foo { class func foo() {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo()", selectorName: "foo", parameters: [], isClass: true, modifiers: [Modifier(name: "class")], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesEnumMethods() {
        XCTAssertEqual("enum Baz { case a; func foo() {} }".parse(), [
            Enum(
                name: "Baz",
                cases: [EnumCase(name: "a")],
                methods: [Function(name: "foo()", selectorName: "foo", parameters: [], definedInTypeName: TypeName(name: "Baz"))]
            )
        ])
    }

    func test_parsesStructMethods() {
        XCTAssertEqual("struct Baz { func foo() {} }".parse(), [
            Struct(name: "Baz", methods: [Function(name: "foo()", selectorName: "foo", parameters: [], definedInTypeName: TypeName(name: "Baz"))])
        ])
    }

    func test_parsesStaticFunction() {
        XCTAssertEqual("class Foo { static func foo() {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo()", selectorName: "foo", isStatic: true, modifiers: [Modifier(name: "static")], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesFreeFunctions() {
        XCTAssertEqual("func foo() {}".parseFunctions(), [
            Function(name: "foo()", selectorName: "foo", isStatic: false, definedInTypeName: nil)
        ])
    }

    func test_parsesFreeFunctionsWithPrivateAccess() {
        XCTAssertEqual("private func foo() {}".parseFunctions(), [
            Function(
                name: "foo()",
                selectorName: "foo",
                accessLevel: (.private),
                isStatic: false,
                modifiers: [Modifier(name: "private")],
                definedInTypeName: nil
            )
        ])
    }

    func test_parsesMethodWithSingleParameter() {
        XCTAssertEqual("class Foo { func foo(bar: Int) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar: Int)", selectorName: "foo(bar:)", parameters: [
                    FunctionParameter(name: "bar", typeName: TypeName(name: "Int"))
                ], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMethodWithVariadicParameter() {
        XCTAssertEqual("class Foo { func foo(bar: Int...) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar: Int...)", selectorName: "foo(bar:)", parameters: [
                        FunctionParameter(name: "bar", typeName: TypeName(name: "Int"), isVariadic: true)
                ], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMethodWithSingleSetParameter() {
        let type = "protocol Foo { func someFunction(aValue: Set<Int>) }".parse().first
        XCTAssertEqual(type,
            Protocol(name: "Foo", methods: [
                Function(name: "someFunction(aValue: Set<Int>)", selectorName: "someFunction(aValue:)", parameters: [
                    FunctionParameter(name: "aValue", typeName: .buildSet(of: .Int))
                ], definedInTypeName: TypeName(name: "Foo"))
            ])
        )
    }

    func test_parsesMethodWithTwoParameters() {
        XCTAssertEqual("class Foo { func foo( bar:   Int,   foo : String  ) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar: Int, foo: String)", selectorName: "foo(bar:foo:)", parameters: [
                    FunctionParameter(name: "bar", typeName: TypeName(name: "Int")),
                    FunctionParameter(name: "foo", typeName: TypeName(name: "String"))
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMethodWithComplexParameters() {
        XCTAssertEqual("class Foo { func foo( bar: [String: String],   foo : ((String, String) -> Void), other: Optional<String>) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar: [String: String], foo: (String, String) -> Void, other: Optional<String>)", selectorName: "foo(bar:foo:other:)", parameters: [
                    FunctionParameter(name: "bar", typeName: TypeName(name: "[String: String]", dictionary: DictionaryType(name: "[String: String]", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "String")), generic: GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String")), GenericTypeParameter(typeName: TypeName(name: "String"))]))),
                    FunctionParameter(name: "foo", typeName: TypeName(name: "(String, String) -> Void", closure: ClosureType(name: "(String, String) -> Void", parameters: [
                        ClosureParameter(typeName: TypeName(name: "String")),
                        ClosureParameter(typeName: TypeName(name: "String"))
                    ], returnTypeName: TypeName(name: "Void")))),
                    FunctionParameter(name: "other", typeName: TypeName(name: "Optional<String>"))
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMethodWithParameterWithTwoNames() {
        XCTAssertEqual("class Foo { func foo(bar Bar: Int, _ foo: Int, fooBar: (_ a: Int, _ b: Int) -> ()) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar Bar: Int, _ foo: Int, fooBar: (_ a: Int, _ b: Int) -> ())", selectorName: "foo(bar:_:fooBar:)", parameters: [
                    FunctionParameter(argumentLabel: "bar", name: "Bar", typeName: TypeName(name: "Int")),
                    FunctionParameter(argumentLabel: nil, name: "foo", typeName: TypeName(name: "Int")),
                    FunctionParameter(name: "fooBar", typeName: TypeName(name: "(_ a: Int, _ b: Int) -> ()", closure: ClosureType(name: "(_ a: Int, _ b: Int) -> ()", parameters: [
                        ClosureParameter(argumentLabel: nil, name: "a", typeName: TypeName(name: "Int")),
                        ClosureParameter(argumentLabel: nil, name: "b", typeName: TypeName(name: "Int"))
                    ], returnTypeName: TypeName(name: "()"))))
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesParametersHavingInnerClosure() {
        XCTAssertEqual("class Foo { func foo(a: Int) { let handler = { (b:Int) in } } }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(a: Int)", selectorName: "foo(a:)", parameters: [
                    FunctionParameter(argumentLabel: "a", name: "a", typeName: TypeName(name: "Int"))
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesInoutParameters() {
        XCTAssertEqual("class Foo { func foo(a: inout Int) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(a: inout Int)", selectorName: "foo(a:)", parameters: [
                    FunctionParameter(argumentLabel: "a", name: "a", typeName: TypeName(name: "inout Int"), isInout: true)
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesParameterSimpleDefaultValue() {
        XCTAssertEqual("class Foo { func foo(a: Int? = nil) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(a: Int? = nil)", selectorName: "foo(a:)", parameters: [
                    FunctionParameter(argumentLabel: "a", name: "a", typeName: TypeName(name: "Int?"), defaultValue: "nil")
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesParameterComplexDefaultValue() {
        XCTAssertEqual("class Foo { func foo(a: Int? = \n\t{ return nil } \n\t ) {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo(a: Int? = { return nil })", selectorName: "foo(a:)", parameters: [
                    FunctionParameter(argumentLabel: "a", name: "a", typeName: TypeName(name: "Int?"), defaultValue: "{ return nil }")
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMultilineParameters() {
        let types = """
        class Foo {
            func foo(bar: [String: String],
                     foo: ((String, String) -> Void),
                     other: Optional<String>) {}
        }
        """.parse()

        XCTAssertEqual(types, [
            Class(name: "Foo", methods: [
                Function(name: "foo(bar: [String: String], foo: (String, String) -> Void, other: Optional<String>)",
                       selectorName: "foo(bar:foo:other:)", parameters: [
                    FunctionParameter(name: "bar", typeName: TypeName(name: "[String: String]", dictionary: DictionaryType(name: "[String: String]", valueTypeName: TypeName(name: "String"), keyTypeName: TypeName(name: "String")), generic: GenericType(name: "Dictionary", typeParameters: [GenericTypeParameter(typeName: TypeName(name: "String")), GenericTypeParameter(typeName: TypeName(name: "String"))]))),
                    FunctionParameter(name: "foo", typeName: TypeName(name: "(String, String) -> Void", closure: ClosureType(name: "(String, String) -> Void", parameters: [
                        ClosureParameter(typeName: TypeName(name: "String")),
                        ClosureParameter(typeName: TypeName(name: "String"))
                    ], returnTypeName: TypeName(name: "Void")))),
                    FunctionParameter(name: "other", typeName: TypeName(name: "Optional<String>"))
                ], returnTypeName: TypeName(name: "Void"), definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_genericMethod_parsesClassFunction() {
        let types = """
        class Foo {
            func foo<T: Equatable>() -> Bar? where T: Equatable { }
            /// Does some foo bar
            ///
            /// - Parameter bar: The awesome bar parameter
            func fooBar<T>(bar: T) where T: Equatable { }
        }
        class Bar {}
        """.parse()
        assertMethods(types)
    }

    func test_genericMethod_parsesProtocolFunction() {
        let types = """
        protocol Foo {
            func foo<T: Equatable>() -> Bar? where T: Equatable
            /// Does some foo bar
            ///
            /// - Parameter bar: The awesome bar parameter
            func fooBar<T>(bar: T) where T: Equatable
        }
        class Bar {}
        """.parse()
        assertMethods(types)
    }

    func test_parsesTupleReturnType() {
        let expectedTypeName = TypeName(name: "(Bar, Int)", tuple: TupleType(name: "(Bar, Int)", elements: [
            TupleElement(name: "0", typeName: TypeName(name: "Bar"), type: Class(name: "Bar")),
            TupleElement(name: "1", typeName: TypeName(name: "Int"))
        ]))

        let types = "class Foo { func foo() -> (Bar, Int) { } }; class Bar {}".parse()
        let method = types.first(where: { $0.name == "Foo" })?.methods.first

        XCTAssertEqual(method?.returnTypeName, expectedTypeName)
        XCTAssertEqual(method?.returnTypeName.isTuple, true)
    }

    func test_parsesClosureReturnType() {
        let types = "class Foo { func foo() -> (Int, Int) -> () { } }".parse()
        let method = types.last?.methods.first

        XCTAssertEqual(method?.returnTypeName, TypeName(
            name: "(Int, Int) -> ()",
            closure: ClosureType(
                name: "(Int, Int) -> ()",
                parameters: [
                    ClosureParameter(typeName: TypeName(name: "Int")),
                    ClosureParameter(typeName: TypeName(name: "Int"))
                ],
                returnTypeName: TypeName(name: "()")
            )
        ))
        XCTAssertEqual(method?.returnTypeName.isClosure, true)
    }

    func test_parsesOptionalClosureReturnType() {
        let types = "protocol Foo { func foo() -> (() -> Void)? }".parse()
        let method = types.last?.methods.first

        XCTAssertEqual(method?.returnTypeName, TypeName(
            name: "(() -> Void)?",
            closure: ClosureType(name: "() -> Void", parameters: [], returnTypeName: TypeName(name: "Void"))
        ))
        XCTAssertEqual(method?.returnTypeName.isClosure, true)
    }

    func test_parsesInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Function(name: "init()", selectorName: "init", returnTypeName: TypeName(name: "Foo"), isStatic: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Function(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = "class Foo { func foo() {}; init() {} }".parse().first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
    }

    func test_parsesFailableInitializer() {
        let fooType = Class(name: "Foo")
        let expectedInitializer = Function(name: "init?()", selectorName: "init", returnTypeName: TypeName(name: "Foo?"), isStatic: true, isFailableInitializer: true, definedInTypeName: TypeName(name: "Foo"))
        expectedInitializer.returnType = fooType
        fooType.rawMethods = [Function(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Foo")), expectedInitializer]

        let type = "class Foo { func foo() {}; init?() {} }".parse().first
        let initializer = type?.initializers.first

        XCTAssertEqual(initializer, expectedInitializer)
    }

    func test_parsesMethodDefinedInTypeName() {
        XCTAssertEqual("class Bar { func foo() {} }".parse(), [
            Class(name: "Bar", methods: [
                Function(name: "foo()", selectorName: "foo", definedInTypeName: TypeName(name: "Bar"))
            ])
        ])
    }

    func test_parsesMethodAnnotations() {
        XCTAssertEqual("class Foo {\n // sourcery: annotation\nfunc foo() {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo()", selectorName: "foo", annotations: ["annotation": true], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesMethodInlineAnnotations() {
        XCTAssertEqual("class Foo {\n /* sourcery: annotation */func foo() {} }".parse(), [
            Class(name: "Foo", methods: [
                Function(name: "foo()", selectorName: "foo", annotations: ["annotation": true], definedInTypeName: TypeName(name: "Foo"))
            ])
        ])
    }

    func test_parsesParameterAnnotations() {
        XCTAssertEqual(
            """
            class Foo {
                //sourcery: foo
                func foo(
                    // sourcery: annotationA
                    a: Int,
                    // sourcery: annotationB
                    b: Int
                ) {}
                //sourcery: bar
                func bar(
                    // sourcery: annotationA
                    a: Int,
                    // sourcery: annotationB
                    b: Int
                ) {}
            }
            """.parse(), [
                Class(name: "Foo", methods: [
                    Function(name: "foo(a: Int, b: Int)", selectorName: "foo(a:b:)", parameters: [
                        FunctionParameter(name: "a", typeName: TypeName(name: "Int"), annotations: ["annotationA": true]),
                        FunctionParameter(name: "b", typeName: TypeName(name: "Int"), annotations: ["annotationB": true])
                    ], annotations: ["foo": true], definedInTypeName: TypeName(name: "Foo")),
                    Function(name: "bar(a: Int, b: Int)", selectorName: "bar(a:b:)", parameters: [
                        FunctionParameter(name: "a", typeName: TypeName(name: "Int"), annotations: ["annotationA": true]),
                        FunctionParameter(name: "b", typeName: TypeName(name: "Int"), annotations: ["annotationB": true])
                    ], annotations: ["bar": true], definedInTypeName: TypeName(name: "Foo"))
                ])
            ]
        )
    }

    func test_parsesParameterInlineAnnotations() {
        XCTAssertEqual(
            """
            class Foo {
                //sourcery: foo
                func foo(/* sourcery: annotationA */a: Int, /* sourcery: annotationB*/b: Int) {}
                //sourcery: bar
                func bar(/* sourcery: annotationA */a: Int, /* sourcery: annotationB*/b: Int) {}
            }
            """.parse(), [
                Class(name: "Foo", methods: [
                    Function(name: "foo(a: Int, b: Int)", selectorName: "foo(a:b:)", parameters: [
                        FunctionParameter(name: "a", typeName: TypeName(name: "Int"), annotations: ["annotationA": true]),
                        FunctionParameter(name: "b", typeName: TypeName(name: "Int"), annotations: ["annotationB": true])
                    ], annotations: ["foo": true], definedInTypeName: TypeName(name: "Foo")),
                    Function(name: "bar(a: Int, b: Int)", selectorName: "bar(a:b:)", parameters: [
                        FunctionParameter(name: "a", typeName: TypeName(name: "Int"), annotations: ["annotationA": true]),
                        FunctionParameter(name: "b", typeName: TypeName(name: "Int"), annotations: ["annotationB": true])
                    ], annotations: ["bar": true], definedInTypeName: TypeName(name: "Foo"))
                ])
            ]
        )
    }
}

private extension String {
    func parse() -> [Type] {
        SwiftSyntaxParser().parse(self).types
    }

    func parseFunctions() -> [Function] {
        SwiftSyntaxParser().parse(self).functions
    }
}

private func assertMethods(_ types: [Type], file: StaticString = #filePath, line: UInt = #line) {
    let fooType = types.first(where: { $0.name == "Foo" })
    let foo = fooType?.methods.first
    let fooBar = fooType?.methods.last

    XCTAssertEqual(foo?.name, "foo<T: Equatable>()", file: file, line: line)
    XCTAssertEqual(foo?.selectorName, "foo", file: file, line: line)
    XCTAssertEqual(foo?.shortName, "foo<T: Equatable>", file: file, line: line)
    XCTAssertEqual(foo?.callName, "foo", file: file, line: line)
    XCTAssertEqual(foo?.returnTypeName, TypeName(name: "Bar? where T: Equatable"), file: file, line: line)
    XCTAssertEqual(foo?.unwrappedReturnTypeName, "Bar", file: file, line: line)
    XCTAssertEqual(foo?.definedInTypeName, TypeName(name: "Foo"), file: file, line: line)

    XCTAssertEqual(fooBar?.name, "fooBar<T>(bar: T)", file: file, line: line)
    XCTAssertEqual(fooBar?.selectorName, "fooBar(bar:)", file: file, line: line)
    XCTAssertEqual(fooBar?.shortName, "fooBar<T>", file: file, line: line)
    XCTAssertEqual(fooBar?.callName, "fooBar", file: file, line: line)
    XCTAssertEqual(fooBar?.returnTypeName, TypeName(name: "Void where T: Equatable"), file: file, line: line)
    XCTAssertEqual(fooBar?.unwrappedReturnTypeName, "Void", file: file, line: line)
    XCTAssertEqual(fooBar?.definedInTypeName, TypeName(name: "Foo"), file: file, line: line)
}
