// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import XCTest
@testable import SourceryRuntime

class TypedTests: XCTestCase {

    // MARK: - AssociatedValue

    func test_AssociatedValue_canReportOptionalViaKVC() {
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(AssociatedValue(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(AssociatedValue(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_AssociatedValue_canReportTupleTypeViaKVC() {
        let sut = AssociatedValue(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_AssociatedValue_canReportClosureTypeViaKVC() {
        let sut = AssociatedValue(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_AssociatedValue_canReportArrayTypeViaKVC() {
        let sut = AssociatedValue(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_AssociatedValue_canReportDictionaryTypeViaKVC() {
        let sut = AssociatedValue(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_AssociatedValue_canReportActualTypeNameViaKVC() {
        let sut = AssociatedValue(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }

    // MARK: - ClosureParameter

    func test_ClosureParameter_canReportOptionalViaKVC() {
        XCTAssertEqual(ClosureParameter(typeName: "Int?".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(ClosureParameter(typeName: "Int!".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(ClosureParameter(typeName: "Int?".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(ClosureParameter(typeName: "Int!".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
        XCTAssertEqual(ClosureParameter(typeName: "Int?".typeName).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
    }

    func test_ClosureParameter_canReportTupleTypeViaKVC() {
        let sut = ClosureParameter(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_ClosureParameter_canReportClosureTypeViaKVC() {
        let sut = ClosureParameter(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_ClosureParameter_canReportArrayTypeViaKVC() {
        let sut = ClosureParameter(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_ClosureParameter_canReportDictionaryTypeViaKVC() {
        let sut = ClosureParameter(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_ClosureParameter_canReportActualTypeNameViaKVC() {
        let sut = ClosureParameter(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }

    // MARK: - MethodParameter

    func test_MethodParameter_canReportOptionalViaKVC() {
        XCTAssertEqual(MethodParameter(typeName: "Int?".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(MethodParameter(typeName: "Int!".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(MethodParameter(typeName: "Int?".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(MethodParameter(typeName: "Int!".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
        XCTAssertEqual(MethodParameter(typeName: "Int?".typeName).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
    }

    func test_MethodParameter_canReportTupleTypeViaKVC() {
        let sut = MethodParameter(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_MethodParameter_canReportClosureTypeViaKVC() {
        let sut = MethodParameter(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_MethodParameter_canReportArrayTypeViaKVC() {
        let sut = MethodParameter(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_MethodParameter_canReportDictionaryTypeViaKVC() {
        let sut = MethodParameter(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_MethodParameter_canReportActualTypeNameViaKVC() {
        let sut = MethodParameter(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }

    // MARK: - TupleElement

    func test_TupleElement_canReportOptionalViaKVC() {
        XCTAssertEqual(TupleElement(typeName: "Int?".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(TupleElement(typeName: "Int!".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(TupleElement(typeName: "Int?".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(TupleElement(typeName: "Int!".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
        XCTAssertEqual(TupleElement(typeName: "Int?".typeName).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
    }

    func test_TupleElement_canReportTupleTypeViaKVC() {
        let sut = TupleElement(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_TupleElement_canReportClosureTypeViaKVC() {
        let sut = TupleElement(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_TupleElement_canReportArrayTypeViaKVC() {
        let sut = TupleElement(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_TupleElement_canReportDictionaryTypeViaKVC() {
        let sut = TupleElement(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_TupleElement_canReportActualTypeNameViaKVC() {
        let sut = TupleElement(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }

    // MARK: - Typealias

    func test_Typealias_canReportOptionalViaKVC() {
        XCTAssertEqual(Typealias(typeName: "Int?".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Typealias(typeName: "Int!".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Typealias(typeName: "Int?".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(Typealias(typeName: "Int!".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
        XCTAssertEqual(Typealias(typeName: "Int?".typeName).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
    }

    func test_Typealias_canReportTupleTypeViaKVC() {
        let sut = Typealias(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_Typealias_canReportClosureTypeViaKVC() {
        let sut = Typealias(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_Typealias_canReportArrayTypeViaKVC() {
        let sut = Typealias(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_Typealias_canReportDictionaryTypeViaKVC() {
        let sut = Typealias(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_Typealias_canReportActualTypeNameViaKVC() {
        let sut = Typealias(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }

    // MARK: - Variable

    func test_Variable_canReportOptionalViaKVC() {
        XCTAssertEqual(Variable(typeName: "Int?".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Variable(typeName: "Int!".typeName).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Variable(typeName: "Int?".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(Variable(typeName: "Int!".typeName).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
        XCTAssertEqual(Variable(typeName: "Int?".typeName).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
    }

    func test_Variable_canReportTupleTypeViaKVC() {
        let sut = Variable(typeName: "(Int, Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_Variable_canReportClosureTypeViaKVC() {
        let sut = Variable(typeName: "(Int) -> (Int)".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_Variable_canReportArrayTypeViaKVC() {
        let sut = Variable(typeName: "[Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_Variable_canReportDictionaryTypeViaKVC() {
        let sut = Variable(typeName: "[Int: Int]".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "isDictionary") as? Bool, true)
    }

    func test_Variable_canReportActualTypeNameViaKVC() {
        let sut = Variable(typeName: "Alias".typeName)
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.value(forKeyPath: "actualTypeName") as? TypeName, "Int".typeName)
    }
}

private extension String {
    var typeName: TypeName {
        typeName()
    }

    func typeName(
        isOptional: Bool = false,
        isImplicitlyUnwrappedOptional: Bool = false
    ) -> TypeName {
        TypeName(
            name: self,
            isOptional: isOptional,
            isImplicitlyUnwrappedOptional: isImplicitlyUnwrappedOptional
        )
    }
}

private extension TypeName {
    static let optionalInt = TypeName(name: "Int?", unwrappedTypeName: "Int", isOptional: true, isImplicitlyUnwrappedOptional: false)
    static let implicitlyUnwrappedOptionalInt = TypeName(name: "Int!", unwrappedTypeName: "Int", isOptional: true, isImplicitlyUnwrappedOptional: true)
}
