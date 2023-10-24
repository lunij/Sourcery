import Foundation
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class StencilTemplateTests2: XCTestCase {
    func test_typesAll_skippingProtocols() {
        XCTAssertEqual("Found {{ types.all.count }} types".generate(), "Found 9 types")
    }

    func test_typesProtocols() {
        XCTAssertEqual("Found {{ types.protocols.count }} protocols".generate(), "Found 3 protocols")
    }

    func test_typesClasses() {
        XCTAssertEqual(
            "Found {{ types.classes.count }} classes, first: {{ types.classes.first.name }}, second: {{ types.classes.last.name }}".generate(),
            "Found 4 classes, first: Foo, second: ProjectFooSubclass"
        )
    }

    func test_typesStructs() {
        XCTAssertEqual("Found {{ types.structs.count }} structs, first: {{ types.structs.first.name }}".generate(), "Found 2 structs, first: Bar")
    }

    func test_typesEnums() {
        XCTAssertEqual("Found {{ types.enums.count }} enums, first: {{ types.enums.first.name }}".generate(), "Found 2 enums, first: FooOptions")
    }

    func test_typesExtensions() {
        XCTAssertEqual("Found {{ types.extensions.count }} extensions, first: {{ types.extensions.first.name }}".generate(), "Found 1 extensions, first: NSObject")
    }

    func test_typesImplementingSpecificProtocol() {
        XCTAssertEqual("Found {{ types.implementing.KnownProtocol.count }} types".generate(), "Found 8 types")
        XCTAssertEqual("Found {{ types.implementing.Decodable.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.implementing.Foo.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.implementing.NSObject.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.implementing.Bar.count|default:\"0\" }} types".generate(), "Found 0 types")

        XCTAssertEqual("{{ types.all|implements:\"KnownProtocol\"|count }}".generate(), "7")
    }

    func test_typesInheritingSpecificClass() {
        XCTAssertEqual("Found {{ types.inheriting.KnownProtocol.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.inheriting.Decodable.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.inheriting.Foo.count }} types".generate(), "Found 2 types")
        XCTAssertEqual("Found {{ types.inheriting.NSObject.count|default:\"0\" }} types".generate(), "Found 0 types")
        XCTAssertEqual("Found {{ types.inheriting.Bar.count|default:\"0\" }} types".generate(), "Found 0 types")

        XCTAssertEqual("{{ types.all|inherits:\"Foo\"|count }}".generate(), "2")
    }

    func test_typesBasedSpecificTypeOrProtocol() {
        XCTAssertEqual("Found {{ types.based.KnownProtocol.count }} types".generate(), "Found 8 types")
        XCTAssertEqual("Found {{ types.based.Decodable.count }} types".generate(), "Found 4 types")
        XCTAssertEqual("Found {{ types.based.Foo.count }} types".generate(), "Found 2 types")
        XCTAssertEqual("Found {{ types.based.NSObject.count }} types".generate(), "Found 3 types")
        XCTAssertEqual("Found {{ types.based.Bar.count|default:\"0\" }} types".generate(), "Found 0 types")

        XCTAssertEqual("{{ types.all|based:\"Decodable\"|count }}".generate(), "4")
    }

    func test_typesExtendsSpecificTypeOrProtocol() {
        XCTAssertEqual("Found {{ types.based.KnownProtocol.count }} types".generate(), "Found 8 types")
        XCTAssertEqual("Found {{ types.based.Decodable.count }} types".generate(), "Found 4 types")
        XCTAssertEqual("Found {{ types.based.Foo.count }} types".generate(), "Found 2 types")
        XCTAssertEqual("Found {{ types.based.NSObject.count }} types".generate(), "Found 3 types")
        XCTAssertEqual("Found {{ types.based.Bar.count|default:\"0\" }} types".generate(), "Found 0 types")

        XCTAssertEqual("{{ types.all|based:\"Decodable\"|count }}".generate(), "4")
    }

    func test_specificType_canRenderAccessLevel() {
        XCTAssertEqual("{{ type.Complex.accessLevel }}".generate(), "public")
    }

    func test_specificType_canAccessSupertype() {
        XCTAssertEqual("{{ type.FooSubclass.supertype.name }}".generate(), "Foo")
    }

    func test_specificType_countsAllVariablesIncludingImplementsAndInherits() {
        XCTAssertEqual("{{ type.ProjectFooSubclass.allVariables.count }}".generate(), "2")
    }

    func test_specificType_canUseAnnotationsFilter() {
        XCTAssertEqual("{% for type in types.all|annotated:\"bar\" %}{{ type.name }}{% endfor %}".generate(), "Bar")
        XCTAssertEqual("{% for type in types.all|annotated:\"foo = 2\" %}{{ type.name }}{% endfor %}".generate(), "FooSubclass")
        XCTAssertEqual("{% for type in types.all|annotated:\"smth.bar = 2\" %}{{ type.name }}{% endfor %}".generate(), "FooSubclass")
        XCTAssertEqual("{% for type in types.all where type.annotations.smth.bar == 2 %}{{ type.name }}{% endfor %}".generate(), "FooSubclass")
    }

    func test_specificType_canUseFilterOnVariables() {
        XCTAssertEqual("{{ type.Complex.allVariables|computed|count }}".generate(), "3")
        XCTAssertEqual("{{ type.Complex.allVariables|stored|count }}".generate(), "3")
        XCTAssertEqual("{{ type.Complex.allVariables|instance|count }}".generate(), "6")
        XCTAssertEqual("{{ type.Complex.allVariables|static|count }}".generate(), "0")
        XCTAssertEqual("{{ type.Complex.allVariables|tuple|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.allVariables|optional|count }}".generate(), "1")

        XCTAssertEqual("{{ type.Complex.allVariables|implements:\"KnownProtocol\"|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.allVariables|based:\"Decodable\"|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.allVariables|inherits:\"NSObject\"|count }}".generate(), "0")
    }

    func test_specificType_canUseFilterOnMethods() {
        XCTAssertEqual("{{ type.Complex.allMethods|instance|count }}".generate(), "3")
        XCTAssertEqual("{{ type.Complex.allMethods|class|count }}".generate(), "1")
        XCTAssertEqual("{{ type.Complex.allMethods|static|count }}".generate(), "1")
        XCTAssertEqual("{{ type.Complex.allMethods|initializer|count }}".generate(), "0")
        XCTAssertEqual("{{ type.Complex.allMethods|count }}".generate(), "5")
    }

    func test_specificType_canUseAccessLevelFilterOnTypes() {
        XCTAssertEqual("{{ types.all|public|count }}".generate(), "3")
        XCTAssertEqual("{{ types.all|open|count }}".generate(), "1")
        XCTAssertEqual("{{ types.all|!private|!fileprivate|!internal|count }}".generate(), "4")
    }

    func test_specificType_canUseAccessLevelFilterOnMethods() {
        XCTAssertEqual("{{ type.Complex.methods|public|count }}".generate(), "1")
        XCTAssertEqual("{{ type.Complex.methods|private|count }}".generate(), "0")
        XCTAssertEqual("{{ type.Complex.methods|internal|count }}".generate(), "4")
    }

    func test_specificType_canUseAccessLevelFilterOnVariables() {
        XCTAssertEqual("{{ type.Complex.variables|publicGet|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.variables|publicSet|count }}".generate(), "1")
        XCTAssertEqual("{{ type.Complex.variables|privateSet|count }}".generate(), "1")
    }

    func test_specificType_canUseDefinedInExtensionFilterOnVariables() {
        XCTAssertEqual("{{ type.Complex.variables|definedInExtension|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.variables|!definedInExtension|count }}".generate(), "4")
    }

    func test_specificType_canUseDefinedInExtensionFilterOnMethods() {
        XCTAssertEqual("{{ type.Complex.methods|definedInExtension|count }}".generate(), "2")
        XCTAssertEqual("{{ type.Complex.methods|!definedInExtension|count }}".generate(), "3")
    }

    func test_specificType_givenTupleVariable_canAccessTupleElements() {
        XCTAssertEqual(
            "{% for var in type.Complex.allVariables|tuple %}{% for e in var.typeName.tuple.elements %}{{ e.typeName.name }},{% endfor %}{% endfor %}".generate(),
            "Int,Bar,Int,Bar,"
        )
    }

    func test_specificType_givenTupleVariable_canAccessTupleElementTypeMetadata() {
        XCTAssertEqual(
            "{% for var in type.Complex.allVariables|tuple %}{% for e in var.typeName.tuple.elements|implements:\"KnownProtocol\" %}{{ e.type.name }},{% endfor %}{% endfor %}".generate(),
            "Bar,Bar,"
        )
    }

    func test_specificType_generatesTypeTypeName() {
        XCTAssertEqual("{{ type.Foo.name }} has {{ type.Foo.variables.first.name }} variable".generate(), "Foo has intValue variable")
    }

    func test_specificType_containedTypes() {
        XCTAssertEqual(
            "{{ type.Options.containedType.InnerOptions.variables.count }} variables, first {{ type.Options.containedType.InnerOptions.variables.first.name }}".generate(),
            "1 variables, first fooInnerOptions"
        )
    }

    func test_specificType_enum() {
        XCTAssertEqual("{% for case in type.Options.cases %} {{ case.name }} {% endfor %}".generate(), " optionA  optionB ")
    }

    func test_specificType_classifiesComputedProperties() {
        XCTAssertEqual("{{ type.Complex.variables.count }}, {{ type.Complex.computedVariables.count }}, {{ type.Complex.storedVariables.count }}".generate(), "6, 3, 3")
    }

    func test_specificType_canAccessVariableTypeInformation() {
        XCTAssertEqual("{% for variable in type.Complex.variables %}{{ variable.type.name }}{% endfor %}".generate(), "FooBar")
    }

    func test_specificType_canRenderVariableIsOptional() {
        XCTAssertEqual("{{ type.Complex.variables.first.isOptional }}".generate(), "0")
    }

    func test_specificType_canRenderVariableDefinedInType() {
        XCTAssertEqual(
            "{% for type in types.all %}{% for variable in type.variables %}{{ variable.definedInType.name }} {% endfor %}{% endfor %}".generate(),
            "Complex Complex Complex Complex Complex Complex Foo Options "
        )
    }

    func test_specificType_canRenderMethodDefinedInType() {
        XCTAssertEqual(
            "{% for type in types.all %}{% for method in type.methods %}{{ method.definedInType.name }} {% endfor %}{% endfor %}".generate(),
            "Complex Complex Complex Complex Complex "
        )
    }

    func test_specificType_responseForTypeInherits() {
        XCTAssertNotEqual("{% if type.Foo.inherits.ProjectClass %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertNotEqual("{% if type.Foo.inherits.Decodable %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertNotEqual("{% if type.Foo.inherits.KnownProtocol %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertNotEqual("{% if type.Foo.inherits.AlternativeProtocol %} TRUE {% endif %}".generate(), " TRUE ")

        XCTAssertEqual("{% if type.ProjectFooSubclass.inherits.Foo %} TRUE {% endif %}".generate(), " TRUE ")
    }

    func test_specificType_responseForTypeImplements() {
        XCTAssertNotEqual("{% if type.Bar.implements.ProjectClass %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertNotEqual("{% if type.Bar.implements.Decodable %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.Bar.implements.KnownProtocol %} TRUE {% endif %}".generate(), " TRUE ")

        XCTAssertEqual("{% if type.ProjectFooSubclass.implements.KnownProtocol %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.ProjectFooSubclass.implements.AlternativeProtocol %} TRUE {% endif %}".generate(), " TRUE ")
    }

    func test_specificType_responseForTypeBased() {
        XCTAssertNotEqual("{% if type.Bar.based.ProjectClass %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.Bar.based.Decodable %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.Bar.based.KnownProtocol %} TRUE {% endif %}".generate(), " TRUE ")

        XCTAssertEqual("{% if type.ProjectFooSubclass.based.KnownProtocol %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.ProjectFooSubclass.based.Foo %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.ProjectFooSubclass.based.Decodable %} TRUE {% endif %}".generate(), " TRUE ")
        XCTAssertEqual("{% if type.ProjectFooSubclass.based.AlternativeProtocol %} TRUE {% endif %}".generate(), " TRUE ")
    }

    func test_additionalArguments_canReflectThem() {
        XCTAssertEqual("{{ argument.some }}".generate(), "value")
    }

    func test_additionalArguments_parsesNumbers() {
        XCTAssertEqual("{% if argument.number > 2 %}TRUE{% endif %}".generate(), "TRUE")
    }
}

private func beforeEachGenerate() -> ([Type], [String: NSObject]){
    let fooType = Class(name: "Foo", variables: [Variable(name: "intValue", typeName: TypeName(name: "Int"))], inheritedTypes: ["NSObject", "Decodable", "AlternativeProtocol"])
    let fooSubclassType = Class(name: "FooSubclass", inheritedTypes: ["Foo", "ProtocolBasedOnKnownProtocol"], annotations: ["foo": NSNumber(value: 2), "smth": ["bar": NSNumber(value: 2)] as NSObject])
    let barType = Struct(name: "Bar", inheritedTypes: ["KnownProtocol", "Decodable"], annotations: ["bar": NSNumber(value: true)])

    let complexType = Struct(name: "Complex", accessLevel: .public, isExtension: false, variables: [])
    let fooVar = Variable(name: "foo", typeName: TypeName(name: "Foo"), accessLevel: (read: .public, write: .private), isComputed: false, definedInTypeName: TypeName(name: "Complex"))
    fooVar.type = fooType
    let barVar = Variable(name: "bar", typeName: TypeName(name: "Bar"), accessLevel: (read: .public, write: .public), isComputed: false, definedInTypeName: TypeName(name: "Complex"))
    barVar.type = barType

    complexType.rawVariables = [
        fooVar,
        barVar,
        Variable(name: "fooBar", typeName: TypeName(name: "Int", isOptional: true), isComputed: true, definedInTypeName: TypeName(name: "Complex")),
        Variable(name: "tuple", typeName: .buildTuple(.Int, TypeName(name: "Bar")), definedInTypeName: TypeName(name: "Complex"))
    ]

    complexType.rawMethods = [
        Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "Int"))], accessLevel: .public, definedInTypeName: TypeName(name: "Complex")),
        Method(name: "foo2(some: Int)", selectorName: "foo2(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "Float"))], isStatic: true, definedInTypeName: TypeName(name: "Complex")),
        Method(name: "foo3(some: Int)", selectorName: "foo3(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "Int"))], isClass: true, definedInTypeName: TypeName(name: "Complex"))
    ]

    let complexTypeExtension = Type(name: "Complex", isExtension: true, variables: [])
    complexTypeExtension.rawVariables = [
        Variable(name: "fooBarFromExtension", typeName: TypeName(name: "Int"), isComputed: true, definedInTypeName: TypeName(name: "Complex")),
        Variable(name: "tupleFromExtension", typeName: .buildTuple(.Int, TypeName(name: "Bar")), isComputed: true, definedInTypeName: TypeName(name: "Complex"))
    ]
    complexTypeExtension.rawMethods = [
        Method(name: "fooFromExtension(some: Int)", selectorName: "fooFromExtension(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "Int"))], definedInTypeName: TypeName(name: "Complex")),
        Method(name: "foo2FromExtension(some: Int)", selectorName: "foo2FromExtension(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "Float"))], definedInTypeName: TypeName(name: "Complex"))
    ]

    let knownProtocol = Protocol(name: "KnownProtocol", variables: [
        Variable(name: "protocolVariable", typeName: TypeName(name: "Int"), isComputed: true, definedInTypeName: TypeName(name: "KnownProtocol"))
        ], methods: [
            Method(name: "foo(some: String)", selectorName: "foo(some:)", parameters: [MethodParameter(name: "some", typeName: TypeName(name: "String"))], accessLevel: .public, definedInTypeName: TypeName(name: "KnownProtocol"))
        ])

    let innerOptionsType = Type(name: "InnerOptions", accessLevel: .public, variables: [
        Variable(name: "fooInnerOptions", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .public), isComputed: false, definedInTypeName: TypeName(name: "InnerOptions"))
        ])
    innerOptionsType.variables.forEach { $0.definedInType = innerOptionsType }
    let optionsType = Enum(name: "Options", accessLevel: .public, inheritedTypes: ["KnownProtocol"], cases: [EnumCase(name: "optionA"), EnumCase(name: "optionB")], variables: [
        Variable(name: "optionVar", typeName: TypeName(name: "String"), accessLevel: (read: .public, write: .public), isComputed: false, definedInTypeName: TypeName(name: "Options"))
        ], containedTypes: [innerOptionsType])

    let types = [
        fooType,
        fooSubclassType,
        complexType,
        complexTypeExtension,
        barType,
        optionsType,
        Enum(name: "FooOptions", accessLevel: .public, inheritedTypes: ["Foo", "KnownProtocol"], rawTypeName: TypeName(name: "Foo"), cases: [EnumCase(name: "fooA"), EnumCase(name: "fooB")]),
        Type(name: "NSObject", accessLevel: .none, isExtension: true, inheritedTypes: ["KnownProtocol"]),
        Class(name: "ProjectClass", accessLevel: .open),
        Class(name: "ProjectFooSubclass", inheritedTypes: ["FooSubclass"]),
        knownProtocol,
        Protocol(name: "AlternativeProtocol"),
        Protocol(name: "ProtocolBasedOnKnownProtocol", inheritedTypes: ["KnownProtocol"])
    ]

    let arguments: [String: NSObject] = ["some": "value" as NSString, "number": NSNumber(value: Float(4))]
    return (types, arguments)
}

private extension String {
    func generate() -> String {
        let (types, arguments) = beforeEachGenerate()
        let (uniqueTypes, _, _) = Composer.uniqueTypesAndFunctions(FileParserResult(path: nil, module: nil, types: types, functions: [], typealiases: []))
        let result = try? StencilTemplate(content: self).render(TemplateContext(
            parserResult: nil,
            types: Types(types: uniqueTypes),
            functions: [],
            arguments: arguments
        ))
        return result ?? ""
    }
}
