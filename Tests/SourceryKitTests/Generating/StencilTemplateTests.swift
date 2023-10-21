import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class StencilTemplateTests: XCTestCase {
    func test_json_whenDictionary_rendersUnprettyJson() {
        let result = try? StencilTemplate(templateString: "{{ argument.json | json }}")
            .render(.fake(arguments: ["json": ["Version": 1] as NSDictionary]))
        XCTAssertEqual(result, "{\"Version\":1}")
    }

    func test_json_whenDictionary_rendersPrettyJson() {
        let result = try? StencilTemplate(templateString: "{{ argument.json | json:true }}")
            .render(.fake(arguments: ["json": ["Version": 1] as NSDictionary]))
        XCTAssertEqual(result, "{\n  \"Version\" : 1\n}")
    }

    func test_json_whenArray_rendersUnprettyJson() {
        let result = try? StencilTemplate(templateString: "{{ argument.json | json }}")
            .render(.fake(arguments: ["json": ["a", "b"] as NSArray]))
        XCTAssertEqual(result, "[\"a\",\"b\"]")
    }

    func test_json_whenArray_rendersPrettyJson() {
        let result = try? StencilTemplate(templateString: "{{ argument.json | json:true }}")
            .render(.fake(arguments: ["json": ["a", "b"] as NSArray]))
        XCTAssertEqual(result, "[\n  \"a\",\n  \"b\"\n]")
    }

    func test_toArray_whenArray_doesNotModifyTheValue() {
        let result = generate("{% for key,value in type.MyClass.variables.2.annotations %}{{ value | toArray }}{% endfor %}")
        XCTAssertEqual(result, "[Hello, beautiful, World]")
    }

    func test_toArray_whenNotArray_transformsItIntoArray() {
        let result = generate("{% for key,value in type.MyClass.variables.3.annotations %}{{ value | toArray }}{% endfor %}")
        XCTAssertEqual(result, "[HelloWorld]")
    }

    func test_count_whenArray() {
        let result = generate("{{ type.MyClass.allVariables | count }}")
        XCTAssertEqual(result, "4")
    }

    func test_isEmpty_givenEmptyArray() {
        let result = generate("{{ type.MyClass.allMethods | isEmpty }}")
        XCTAssertEqual(result, "true")
    }

    func test_isEmpty_givenNonEmptyArray() {
        let result = generate("{{ type.MyClass.allVariables | isEmpty }}")
        XCTAssertEqual(result, "false")
    }

    func test_sorted_givenArray() {
        let result = generate("{% for key,value in type.MyClass.variables.2.annotations %}{{ value | sorted:\"description\" }}{% endfor %}")
        XCTAssertEqual(result, "[beautiful, Hello, World]")
    }

    func test_sortedDescending_givenArray() {
        let result = generate("{% for key,value in type.MyClass.variables.2.annotations %}{{ value | sortedDescending:\"description\" }}{% endfor %}")
        XCTAssertEqual(result, "[World, Hello, beautiful]")
    }

    func test_reversed_givenArray() {
        let result = generate("{% for key,value in type.MyClass.variables.2.annotations %}{{ value | reversed }}{% endfor %}")
        XCTAssertEqual(result, "[World, beautiful, Hello]")
    }

    func test_upperFirstLetter() {
        XCTAssertEqual(generate("{{\"helloWorld\" | upperFirstLetter }}"), "HelloWorld")
    }

    func test_lowerFirstLetter() {
        XCTAssertEqual(generate("{{\"HelloWorld\" | lowerFirstLetter }}"), "helloWorld")
    }

    func test_uppercase() {
        XCTAssertEqual(generate("{{ \"HelloWorld\" | uppercase }}"), "HELLOWORLD")
    }

    func test_lowercase() {
        XCTAssertEqual(generate("{{ \"HelloWorld\" | lowercase }}"), "helloworld")
    }

    func test_capitalise() {
        XCTAssertEqual(generate("{{ \"helloWorld\" | capitalise }}"), "Helloworld")
    }

    func test_deletingLastComponent() {
        XCTAssertEqual(generate("{{ \"/Path/Class.swift\" | deletingLastComponent }}"), "/Path")
    }

    func test_contains() {
        XCTAssertEqual(generate("{{ \"FooBar\" | contains:\"oo\" }}"), "true")
        XCTAssertEqual(generate("{{ \"FooBar\" | contains:\"xx\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !contains:\"oo\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !contains:\"xx\" }}"), "true")
    }

    func test_hasPrefix() {
        XCTAssertEqual(generate("{{ \"FooBar\" | hasPrefix:\"Foo\" }}"), "true")
        XCTAssertEqual(generate("{{ \"FooBar\" | hasPrefix:\"Bar\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !hasPrefix:\"Foo\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !hasPrefix:\"Bar\" }}"), "true")
    }

    func test_hasSuffix() {
        XCTAssertEqual(generate("{{ \"FooBar\" | hasSuffix:\"Bar\" }}"), "true")
        XCTAssertEqual(generate("{{ \"FooBar\" | hasSuffix:\"Foo\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !hasSuffix:\"Bar\" }}"), "false")
        XCTAssertEqual(generate("{{ \"FooBar\" | !hasSuffix:\"Foo\" }}"), "true")
    }

    func test_replace() {
        XCTAssertEqual(generate("{{\"helloWorld\" | replace:\"he\",\"bo\" | replace:\"llo\",\"la\" }}"), "bolaWorld")
        XCTAssertEqual(generate("{{\"helloWorldhelloWorld\" | replace:\"hello\",\"hola\" }}"), "holaWorldholaWorld")
        XCTAssertEqual(generate("{{\"helloWorld\" | replace:\"hello\",\"\" }}"), "World")
        XCTAssertEqual(generate("{{\"helloWorld\" | replace:\"foo\",\"bar\" }}"), "helloWorld")
    }

    func test_typeName() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName }}"), "myClass")
    }

    func test_typeName_upperFirstLetter() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | upperFirstLetter }}"), "MyClass")
    }

    func test_typeName_lowerFirstLetter() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.1.typeName | lowerFirstLetter }}"), "myClass")
    }

    func test_typeName_uppercase() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | uppercase }}"), "MYCLASS")
    }

    func test_typeName_lowercase() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.1.typeName | lowercase }}"), "myclass")
    }

    func test_typeName_capitalise() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.1.typeName | capitalise }}"), "Myclass")
    }

    func test_typeName_contains() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | contains:\"my\" }}"), "true")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | contains:\"xx\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !contains:\"my\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !contains:\"xx\" }}"), "true")
    }

    func test_typeName_hasPrefix() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | hasPrefix:\"my\" }}"), "true")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | hasPrefix:\"My\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !hasPrefix:\"my\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !hasPrefix:\"My\" }}"), "true")
    }

    func test_typeName_hasSuffix() {
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | hasSuffix:\"Class\" }}"), "true")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | hasSuffix:\"class\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !hasSuffix:\"Class\" }}"), "false")
        XCTAssertEqual(generate("{{ type.MyClass.variables.0.typeName | !hasSuffix:\"class\" }}"), "true")
    }

    func test_typeName_replace() {
        XCTAssertEqual(generate("{{type.MyClass.variables.0.typeName | replace:\"my\",\"My\" | replace:\"Class\",\"Struct\" }}"), "MyStruct")
        XCTAssertEqual(generate("{{type.MyClass.variables.0.typeName | replace:\"s\",\"z\" }}"), "myClazz")
        XCTAssertEqual(generate("{{type.MyClass.variables.0.typeName | replace:\"my\",\"\" }}"), "Class")
        XCTAssertEqual(generate("{{type.MyClass.variables.0.typeName | replace:\"foo\",\"bar\" }}"), "myClass")
    }

    func test_rethrowsTemplateParsingErrors() {
        XCTAssertThrowsError(
            try StencilTemplate(templateString: "{% tag %}").render(.init(parserResult: nil, types: Types(types: []), functions: [], arguments: [:]))
        ) { error in
            XCTAssertEqual("\(error)", ": Unknown template tag 'tag'")
        }
    }

    func test_includesPartialTemplates() throws {
        let output = try Output(.createTestDirectory(suffixed: #function))

        let templatePath = Stubs.templateDirectory + Path("Include.stencil")
        let expectedResult = """
        // Generated using Sourcery

        partial template content

        """

        try Sourcery(cacheDisabled: true).processConfiguration(.stub(
            sources: .paths(Paths(include: [Stubs.sourceDirectory])),
            templates: Paths(include: [templatePath]),
            output: output
        ))

        let result = try (output.path + templatePath.generatedPath).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }
}

private extension TemplateContext {
    static func fake(
        parserResult: FileParserResult? = nil,
        types: Types = .init(types: []),
        functions: [SourceryMethod] = [],
        arguments: [String: NSObject] = [:]
    ) -> Self {
        .init(
            parserResult: parserResult,
            types: types,
            functions: functions,
            arguments: arguments
        )
    }
}

private func generate(_ template: String) -> String {
    let arrayAnnotations = Variable(name: "annotated1", typeName: TypeName(name: "MyClass"))
    arrayAnnotations.annotations = ["Foo": ["Hello", "beautiful", "World"] as NSArray]
    let singleAnnotation = Variable(name: "annotated2", typeName: TypeName(name: "MyClass"))
    singleAnnotation.annotations = ["Foo": "HelloWorld" as NSString]
    let result = try? StencilTemplate(templateString: template).render(TemplateContext(
        parserResult: nil,
        types: Types(types: [
            Class(name: "MyClass", variables: [
                Variable(name: "lowerFirstLetter", typeName: TypeName(name: "myClass")),
                Variable(name: "upperFirstLetter", typeName: TypeName(name: "MyClass")),
                arrayAnnotations,
                singleAnnotation
            ])
        ]),
        functions: [],
        arguments: [:]
    ))
    return result ?? ""
}
