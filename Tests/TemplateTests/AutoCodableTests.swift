import Foundation
import XCTest
@testable import ContextExamples

class AutoCodableTests: XCTestCase {
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    let decoder = JSONDecoder()

    func test_enumWithCaseKey_codesValueWithAssociatedValues() {
        let value = AssociatedValuesEnum.someCase(id: 0, name: "a")

        let encoded = try! encoder.encode(value)

        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "id" : 0,
          "name" : "a",
          "type" : "someCase"
        }
        """)

        let decoded = try! decoder.decode(AssociatedValuesEnum.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }

    func test_enumWithCaseKey_cannotUseValueWithUnnamedAssociatedValues() {
        let value = AssociatedValuesEnum.unnamedCase(0, "a")
        let encoded = "{\"type\" : \"unnamedCase\"}".data(using: .utf8)!

        XCTAssertThrowsError(try encoder.encode(value))
        XCTAssertThrowsError(try decoder.decode(AssociatedValuesEnum.self, from: encoded))
    }

    func test_enumWithCaseKey_cannotUseValueWithMixedAssociatedValues() {
        let value = AssociatedValuesEnum.mixCase(0, name: "a")
        let encoded = "{\"type\" : \"mixCase\"}".data(using: .utf8)!

        XCTAssertThrowsError(try encoder.encode(value))
        XCTAssertThrowsError(try decoder.decode(AssociatedValuesEnum.self, from: encoded))
    }

    func test_enumWithCaseKey_codesValueWithoutAssociatedValues() {
        let value = AssociatedValuesEnum.anotherCase

        let encoded = try! encoder.encode(value)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "type" : "anotherCase"
        }
        """)

        let decoded = try! decoder.decode(AssociatedValuesEnum.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }

    func test_enumWithoutCaseKey_codesValueWithAssociatedValues() {
        let value = AssociatedValuesEnumNoCaseKey.someCase(id: 0, name: "a")

        let encoded = try! encoder.encode(value)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "someCase" : {
            "id" : 0,
            "name" : "a"
          }
        }
        """)

        let decoded = try! decoder.decode(AssociatedValuesEnumNoCaseKey.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }

    func test_enumWithoutCaseKey_codesValueWithUnnamedAssociatedValues() {
        let value = AssociatedValuesEnumNoCaseKey.unnamedCase(0, "a")

        let encoded = try! encoder.encode(value)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "unnamedCase" : [
            0,
            "a"
          ]
        }
        """)

        let decoded = try! decoder.decode(AssociatedValuesEnumNoCaseKey.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }

    func test_enumWithoutCaseKey_cannotUseValueWithMixedAssociatedValues() {
        let value = AssociatedValuesEnumNoCaseKey.mixCase(0, name: "a")
        let encoded = "{\"type\" : \"mixCase\"}".data(using: .utf8)!

        XCTAssertThrowsError(try encoder.encode(value))
        XCTAssertThrowsError(try decoder.decode(AssociatedValuesEnumNoCaseKey.self, from: encoded))
    }

    func test_enumWithoutCaseKey_codesValueWithoutAssoicatedValues() {
        let value = AssociatedValuesEnumNoCaseKey.anotherCase

        let encoded = try! encoder.encode(value)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "anotherCase" : {

          }
        }
        """)

        let decoded = try! decoder.decode(AssociatedValuesEnumNoCaseKey.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
}
