// swiftlint:disable file_length
private func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        compare(lValue, rValue)
    case (nil, nil):
        true
    default:
        false
    }
}

private func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}

// MARK: - AutoEquatable for classes, protocols, structs

// MARK: - AutoEquatableAnnotatedClass AutoEquatable

extension AutoEquatableAnnotatedClass: Equatable {}
func == (lhs: AutoEquatableAnnotatedClass, rhs: AutoEquatableAnnotatedClass) -> Bool {
    guard lhs.moneyInThePocket == rhs.moneyInThePocket else { return false }
    return true
}

// MARK: - AutoEquatableAnnotatedClassAnnotatedInherited AutoEquatable

extension AutoEquatableAnnotatedClassAnnotatedInherited: Equatable {}
THIS WONT COMPILE, WE DONT SUPPORT INHERITANCE for AutoEquatable
func == (lhs: AutoEquatableAnnotatedClassAnnotatedInherited, rhs: AutoEquatableAnnotatedClassAnnotatedInherited) -> Bool {
    guard lhs.middleName == rhs.middleName else { return false }
    return true
}

// MARK: - AutoEquatableClass AutoEquatable

extension AutoEquatableClass: Equatable {}
func == (lhs: AutoEquatableClass, rhs: AutoEquatableClass) -> Bool {
    guard lhs.firstName == rhs.firstName else { return false }
    guard lhs.lastName == rhs.lastName else { return false }
    guard compareArrays(lhs: lhs.parents, rhs: rhs.parents, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.age, rhs: rhs.age, compare: ==) else { return false }
    guard lhs.moneyInThePocket == rhs.moneyInThePocket else { return false }
    guard compareOptionals(lhs: lhs.friends, rhs: rhs.friends, compare: ==) else { return false }
    return true
}

// MARK: - AutoEquatableClassInherited AutoEquatable

extension AutoEquatableClassInherited: Equatable {}
THIS WONT COMPILE, WE DONT SUPPORT INHERITANCE for AutoEquatable
func == (lhs: AutoEquatableClassInherited, rhs: AutoEquatableClassInherited) -> Bool {
    guard compareOptionals(lhs: lhs.middleName, rhs: rhs.middleName, compare: ==) else { return false }
    return true
}

// MARK: - AutoEquatableNSObject AutoEquatable

func == (lhs: AutoEquatableNSObject, rhs: AutoEquatableNSObject) -> Bool {
    guard lhs.firstName == rhs.firstName else { return false }
    return true
}

// MARK: - AutoEquatableProtocol AutoEquatable

func == (lhs: AutoEquatableProtocol, rhs: AutoEquatableProtocol) -> Bool {
    guard lhs.width == rhs.width else { return false }
    guard lhs.height == rhs.height else { return false }
    guard lhs.name == rhs.name else { return false }
    return true
}

// MARK: - AutoEquatableStruct AutoEquatable

extension AutoEquatableStruct: Equatable {}
func == (lhs: AutoEquatableStruct, rhs: AutoEquatableStruct) -> Bool {
    guard lhs.firstName == rhs.firstName else { return false }
    guard lhs.lastName == rhs.lastName else { return false }
    guard compareArrays(lhs: lhs.parents, rhs: rhs.parents, compare: ==) else { return false }
    guard lhs.moneyInThePocket == rhs.moneyInThePocket else { return false }
    guard compareOptionals(lhs: lhs.friends, rhs: rhs.friends, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.age, rhs: rhs.age, compare: ==) else { return false }
    return true
}

// MARK: - AutoEquatable for Enums

// MARK: - AutoEquatableEnum AutoEquatable

extension AutoEquatableEnum: Equatable {}
func == (lhs: AutoEquatableEnum, rhs: AutoEquatableEnum) -> Bool {
    switch (lhs, rhs) {
    case (.one, .one):
        return true
    case let (.two(lhsFirst, lhsSecond), .two(rhsFirst, rhsSecond)):
        if lhsFirst != rhsFirst { return false }
        if lhsSecond != rhsSecond { return false }
        return true
    case let (.three(lhs), .three(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - AutoEquatableEnumWithOneCase AutoEquatable

extension AutoEquatableEnumWithOneCase: Equatable {}
func == (lhs: AutoEquatableEnumWithOneCase, rhs: AutoEquatableEnumWithOneCase) -> Bool {
    switch (lhs, rhs) {
    case (.one, .one):
        true
    }
}
