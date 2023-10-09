// Generated using Sourcery 2.0.2 — https://github.com/lunij/Sourcery

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
        let sut = AssociatedValue(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_AssociatedValue_canReportClosureTypeViaKVC() {
        let sut = AssociatedValue(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_AssociatedValue_canReportArrayTypeViaKVC() {
        let sut = AssociatedValue(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_AssociatedValue_canReportDictionaryTypeViaKVC() {
        let sut = AssociatedValue(typeName: .intIntDictionary)
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
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(ClosureParameter(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(ClosureParameter(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_ClosureParameter_canReportTupleTypeViaKVC() {
        let sut = ClosureParameter(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_ClosureParameter_canReportClosureTypeViaKVC() {
        let sut = ClosureParameter(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_ClosureParameter_canReportArrayTypeViaKVC() {
        let sut = ClosureParameter(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_ClosureParameter_canReportDictionaryTypeViaKVC() {
        let sut = ClosureParameter(typeName: .intIntDictionary)
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
        XCTAssertEqual(MethodParameter(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(MethodParameter(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(MethodParameter(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(MethodParameter(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(MethodParameter(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_MethodParameter_canReportTupleTypeViaKVC() {
        let sut = MethodParameter(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_MethodParameter_canReportClosureTypeViaKVC() {
        let sut = MethodParameter(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_MethodParameter_canReportArrayTypeViaKVC() {
        let sut = MethodParameter(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_MethodParameter_canReportDictionaryTypeViaKVC() {
        let sut = MethodParameter(typeName: .intIntDictionary)
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
        XCTAssertEqual(TupleElement(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(TupleElement(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(TupleElement(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(TupleElement(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(TupleElement(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_TupleElement_canReportTupleTypeViaKVC() {
        let sut = TupleElement(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_TupleElement_canReportClosureTypeViaKVC() {
        let sut = TupleElement(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_TupleElement_canReportArrayTypeViaKVC() {
        let sut = TupleElement(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_TupleElement_canReportDictionaryTypeViaKVC() {
        let sut = TupleElement(typeName: .intIntDictionary)
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
        XCTAssertEqual(Typealias(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Typealias(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(Typealias(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(Typealias(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Typealias(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_Typealias_canReportTupleTypeViaKVC() {
        let sut = Typealias(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_Typealias_canReportClosureTypeViaKVC() {
        let sut = Typealias(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_Typealias_canReportArrayTypeViaKVC() {
        let sut = Typealias(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_Typealias_canReportDictionaryTypeViaKVC() {
        let sut = Typealias(typeName: .intIntDictionary)
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
        XCTAssertEqual(Variable(typeName: .optionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Variable(typeName: .optionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, false)
        XCTAssertEqual(Variable(typeName: .optionalInt).value(forKeyPath: "unwrappedTypeName") as? String, "Int")
        XCTAssertEqual(Variable(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isOptional") as? Bool, true)
        XCTAssertEqual(Variable(typeName: .implicitlyUnwrappedOptionalInt).value(forKeyPath: "isImplicitlyUnwrappedOptional") as? Bool, true)
    }

    func test_Variable_canReportTupleTypeViaKVC() {
        let sut = Variable(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.value(forKeyPath: "isTuple") as? Bool, true)
    }

    func test_Variable_canReportClosureTypeViaKVC() {
        let sut = Variable(typeName: .closure)
        XCTAssertEqual(sut.value(forKeyPath: "isClosure") as? Bool, true)
    }

    func test_Variable_canReportArrayTypeViaKVC() {
        let sut = Variable(typeName: .intArray)
        XCTAssertEqual(sut.value(forKeyPath: "isArray") as? Bool, true)
    }

    func test_Variable_canReportDictionaryTypeViaKVC() {
        let sut = Variable(typeName: .intIntDictionary)
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
        TypeName(name: self)
    }
}

private extension TypeName {
    static let int = TypeName(name: "Int")
    static let optionalInt = TypeName(name: "Int?", unwrappedTypeName: "Int", isOptional: true, isImplicitlyUnwrappedOptional: false)
    static let implicitlyUnwrappedOptionalInt = TypeName(name: "Int!", unwrappedTypeName: "Int", isOptional: true, isImplicitlyUnwrappedOptional: true)
    static let doubleIntTuple = TypeName(name: "(Int, Int)", tuple: .init(elements: [.init(typeName: .int), .init(typeName: .int)]))
    static let closure = TypeName(name: "(Int) -> Int", closure: .init(name: "(Int) -> Int", parameters: [.init(typeName: .int)], returnTypeName: .int))
    static let intArray = TypeName(name: "[Int]", array: .init(name: "[Int]", elementTypeName: .int))
    static let intIntDictionary = TypeName(name: "[Int: Int]", dictionary: .init(name: "[Int: Int]", valueTypeName: .int, keyTypeName: .int))
}
