import Foundation

public struct FSEvent: Equatable, Sendable {
    public let id: FSEventStreamEventId
    public let path: String
    public let flags: Flags

    public struct Flags: OptionSet, Sendable, CustomDebugStringConvertible {
        public let rawValue: FSEventStreamEventFlags

        public init(rawValue: FSEventStreamEventFlags) {
            self.rawValue = rawValue
        }
        
        public init(_ value: Int) {
            self.init(rawValue: FSEventStreamEventFlags(value))
        }

        public static let none = Flags(kFSEventStreamEventFlagNone)

        public static let isDirectory = Flags(kFSEventStreamEventFlagItemIsDir)
        public static let isFile = Flags(kFSEventStreamEventFlagItemIsFile)
        public static let isHardlink = Flags(kFSEventStreamEventFlagItemIsHardlink)
        public static let isLastHardlink = Flags(kFSEventStreamEventFlagItemIsLastHardlink)
        public static let isSymlink = Flags(kFSEventStreamEventFlagItemIsSymlink)

        public static let created = Flags(kFSEventStreamEventFlagItemCreated)
        public static let modified = Flags(kFSEventStreamEventFlagItemModified)
        public static let removed = Flags(kFSEventStreamEventFlagItemRemoved)
        public static let renamed = Flags(kFSEventStreamEventFlagItemRenamed)

        public static let changeOwner = Flags(kFSEventStreamEventFlagItemChangeOwner)
        public static let finderInfoModified = Flags(kFSEventStreamEventFlagItemFinderInfoMod)
        public static let inodeMetaModified = Flags(kFSEventStreamEventFlagItemInodeMetaMod)
        public static let xattrsModified = Flags(kFSEventStreamEventFlagItemXattrMod)

        public var debugDescription: String {
            var flags: [String] = []

            if contains(.isDirectory) { flags.append("isDirectory") }
            if contains(.isFile) { flags.append("isFile") }
            if contains(.isHardlink) { flags.append("isHardlink") }
            if contains(.isLastHardlink) { flags.append("isLastHardlink") }
            if contains(.isSymlink) { flags.append("isSymlink") }
            
            if contains(.created) { flags.append("created") }
            if contains(.modified) { flags.append("modified") }
            if contains(.removed) { flags.append("removed") }
            if contains(.renamed) { flags.append("renamed") }
            
            if contains(.changeOwner) { flags.append("changeOwner") }
            if contains(.finderInfoModified) { flags.append("finderInfoModified") }
            if contains(.inodeMetaModified) { flags.append("inodeMetaModified") }
            if contains(.xattrsModified) { flags.append("xattrsModified") }

            if flags.isEmpty {
                return "none"
            }

            return flags.joined(separator: " | ")
        }
    }
}
