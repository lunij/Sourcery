// swiftlint:disable all

// MARK: - AutoHashable for classes, protocols, structs

// MARK: - AutoHashableClass AutoHashable

extension AutoHashableClass: Hashable {
    func hash(into hasher: inout Hasher) {
        firstName.hash(into: &hasher)
        lastName.hash(into: &hasher)
        parents.hash(into: &hasher)
        universityGrades.hash(into: &hasher)
        moneyInThePocket.hash(into: &hasher)
        age.hash(into: &hasher)
        friends.hash(into: &hasher)
    }
}

// MARK: - AutoHashableClassFromNonHashableInherited AutoHashable

extension AutoHashableClassFromNonHashableInherited: Hashable {
    func hash(into hasher: inout Hasher) {
        lastName.hash(into: &hasher)
    }
}

// MARK: - AutoHashableClassFromNonHashableInheritedInherited AutoHashable

extension AutoHashableClassFromNonHashableInheritedInherited: Hashable {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        prefix.hash(into: &hasher)
    }
}

// MARK: - AutoHashableClassInherited AutoHashable

extension AutoHashableClassInherited: Hashable {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        middleName.hash(into: &hasher)
    }
}

// MARK: - AutoHashableClassInheritedInherited AutoHashable

extension AutoHashableClassInheritedInherited: Hashable {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        prefix.hash(into: &hasher)
    }
}

// MARK: - AutoHashableFromHashableInherited AutoHashable

extension AutoHashableFromHashableInherited: Hashable {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        lastName.hash(into: &hasher)
    }
}

// MARK: - AutoHashableNSObject AutoHashable

extension AutoHashableNSObject {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        firstName.hash(into: &hasher)
    }
}

// MARK: - AutoHashableNSObjectInherited AutoHashable

extension AutoHashableNSObjectInherited {
    override func hash(into hasher: inout Hasher) {
        super.hash(into: hasher)
        lastName.hash(into: &hasher)
    }
}

// MARK: - AutoHashableProtocol AutoHashable

extension AutoHashableProtocol {
    func hash(into hasher: inout Hasher) {
        width.hash(into: &hasher)
        height.hash(into: &hasher)
        type(of: self).name.hash(into: &hasher)
    }
}

// MARK: - AutoHashableStruct AutoHashable

extension AutoHashableStruct: Hashable {
    func hash(into hasher: inout Hasher) {
        firstName.hash(into: &hasher)
        lastName.hash(into: &hasher)
        parents.hash(into: &hasher)
        universityGrades.hash(into: &hasher)
        moneyInThePocket.hash(into: &hasher)
        age.hash(into: &hasher)
        friends.hash(into: &hasher)
    }
}

// MARK: - AutoHashable for Enums

// MARK: - AutoHashableEnum AutoHashable

extension AutoHashableEnum: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .one:
            1.hash(into: &hasher)
        case let .two(first, second):
            2.hash(into: &hasher)
            first.hash(into: &hasher)
            second.hash(into: &hasher)
        case let .three(data):
            3.hash(into: &hasher)
            data.hash(into: &hasher)
        }
    }
}
