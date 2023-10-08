
import Foundation

protocol AutoCases {}

enum AutoCasesEnum: AutoCases {
    case north
    case south
    case east
    case west
}

enum AutoCasesOneValueEnum: AutoCases {
    case one
}

public enum AutoCasesHasAssociatedValuesEnum: AutoCases {
    case foo(test: String)
    case bar(number: Int)
}
