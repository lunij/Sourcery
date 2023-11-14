// Generated using Sourcery

import XCTest
@testable import SourceryKit

class TypedTests: XCTestCase {

    // MARK: - AssociatedValue

    func test_AssociatedValue_canReportOptional() {
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(AssociatedValue(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(AssociatedValue(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(AssociatedValue(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_AssociatedValue_canReportTupleType() {
        let sut = AssociatedValue(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_AssociatedValue_canReportClosureType() {
        let sut = AssociatedValue(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_AssociatedValue_canReportArrayType() {
        let sut = AssociatedValue(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_AssociatedValue_canReportDictionaryType() {
        let sut = AssociatedValue(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_AssociatedValue_canReportActualTypeName() {
        let sut = AssociatedValue(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
    }

    // MARK: - ClosureParameter

    func test_ClosureParameter_canReportOptional() {
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(ClosureParameter(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(ClosureParameter(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(ClosureParameter(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_ClosureParameter_canReportTupleType() {
        let sut = ClosureParameter(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_ClosureParameter_canReportClosureType() {
        let sut = ClosureParameter(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_ClosureParameter_canReportArrayType() {
        let sut = ClosureParameter(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_ClosureParameter_canReportDictionaryType() {
        let sut = ClosureParameter(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_ClosureParameter_canReportActualTypeName() {
        let sut = ClosureParameter(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
    }

    // MARK: - FunctionParameter

    func test_FunctionParameter_canReportOptional() {
        XCTAssertEqual(FunctionParameter(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(FunctionParameter(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(FunctionParameter(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(FunctionParameter(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(FunctionParameter(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_FunctionParameter_canReportTupleType() {
        let sut = FunctionParameter(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_FunctionParameter_canReportClosureType() {
        let sut = FunctionParameter(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_FunctionParameter_canReportArrayType() {
        let sut = FunctionParameter(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_FunctionParameter_canReportDictionaryType() {
        let sut = FunctionParameter(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_FunctionParameter_canReportActualTypeName() {
        let sut = FunctionParameter(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
    }

    // MARK: - TupleElement

    func test_TupleElement_canReportOptional() {
        XCTAssertEqual(TupleElement(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(TupleElement(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(TupleElement(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(TupleElement(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(TupleElement(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_TupleElement_canReportTupleType() {
        let sut = TupleElement(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_TupleElement_canReportClosureType() {
        let sut = TupleElement(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_TupleElement_canReportArrayType() {
        let sut = TupleElement(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_TupleElement_canReportDictionaryType() {
        let sut = TupleElement(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_TupleElement_canReportActualTypeName() {
        let sut = TupleElement(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
    }

    // MARK: - Typealias

    func test_Typealias_canReportOptional() {
        XCTAssertEqual(Typealias(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(Typealias(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(Typealias(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(Typealias(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(Typealias(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_Typealias_canReportTupleType() {
        let sut = Typealias(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_Typealias_canReportClosureType() {
        let sut = Typealias(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_Typealias_canReportArrayType() {
        let sut = Typealias(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_Typealias_canReportDictionaryType() {
        let sut = Typealias(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_Typealias_canReportActualTypeName() {
        let sut = Typealias(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
    }

    // MARK: - Variable

    func test_Variable_canReportOptional() {
        XCTAssertEqual(Variable(typeName: .optionalInt).isOptional, true)
        XCTAssertEqual(Variable(typeName: .optionalInt).isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual(Variable(typeName: .optionalInt).unwrappedTypeName, "Int")
        XCTAssertEqual(Variable(typeName: .implicitlyUnwrappedOptionalInt).isOptional, true)
        XCTAssertEqual(Variable(typeName: .implicitlyUnwrappedOptionalInt).isImplicitlyUnwrappedOptional, true)
    }

    func test_Variable_canReportTupleType() {
        let sut = Variable(typeName: .doubleIntTuple)
        XCTAssertEqual(sut.isTuple, true)
    }

    func test_Variable_canReportClosureType() {
        let sut = Variable(typeName: .closure)
        XCTAssertEqual(sut.isClosure, true)
    }

    func test_Variable_canReportArrayType() {
        let sut = Variable(typeName: .intArray)
        XCTAssertEqual(sut.isArray, true)
    }

    func test_Variable_canReportDictionaryType() {
        let sut = Variable(typeName: .intIntDictionary)
        XCTAssertEqual(sut.isDictionary, true)
    }

    func test_Variable_canReportActualTypeName() {
        let sut = Variable(typeName: "Alias".typeName)
        XCTAssertEqual(sut.actualTypeName, "Alias".typeName)

        sut.typeName.actualTypeName = "Int".typeName
        XCTAssertEqual(sut.actualTypeName, "Int".typeName)
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
