import CoreServices
import Foundation

public class FSEventStream {
    public typealias Callback = ([FSEvent]) -> Void

    let callback: Callback
    let queue: DispatchQueue
    let eventStream: FSEventStreamRef

    public convenience init?(
        path: String,
        since startId: FSEventStreamEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
        updateInterval: CFTimeInterval = 0,
        options: Options = .fileEvents,
        queue: DispatchQueue = .global(),
        callback: @escaping Callback
    ) {
        self.init(paths: [path], since: startId, updateInterval: updateInterval, options: options, queue: queue, callback: callback)
    }

    public init?(
        paths: [String],
        since startId: FSEventStreamEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
        updateInterval: CFTimeInterval = 0,
        options: Options = .fileEvents,
        queue: DispatchQueue = .global(),
        callback: @escaping Callback
    ) {
        self.callback = callback
        self.queue = queue

        let flags = options.union(.useCFTypes).rawValue

        let objcWrapper = FSEventStreamObjCWrapper()
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(objcWrapper).toOpaque(),
            retain: { ptrToRetain in
                guard let ptrToRetain else { return nil }
                let u = Unmanaged.passRetained(Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(ptrToRetain).takeUnretainedValue())
                return unsafeBitCast(u.takeUnretainedValue(), to: UnsafeRawPointer.self)
            },
            release: { ptrToRelease in
                guard let ptrToRelease else { return }
                Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(ptrToRelease).release()
            },
            copyDescription: nil
        )
        guard let eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventStreamCallback,
            &context,
            paths as CFArray,
            startId,
            updateInterval,
            flags
        ) else {
            return nil
        }
        self.eventStream = eventStream

        FSEventStreamSetDispatchQueue(eventStream, queue)

        objcWrapper.swiftStream = self

        FSEventStreamStart(eventStream)
    }

    deinit {
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
    }

    public struct Options: OptionSet {
        public let rawValue: FSEventStreamCreateFlags

        public init(rawValue: FSEventStreamCreateFlags) {
            self.rawValue = rawValue
        }

        public init(_ value: Int) {
            self.init(rawValue: FSEventStreamCreateFlags(value))
        }

        public static let none = Options(kFSEventStreamCreateFlagNone)
        public static let useCFTypes = Options(kFSEventStreamCreateFlagUseCFTypes)
        public static let noDefer = Options(kFSEventStreamCreateFlagNoDefer)
        public static let watchRoot = Options(kFSEventStreamCreateFlagWatchRoot)
        public static let ignoreSelf = Options(kFSEventStreamCreateFlagIgnoreSelf)
        public static let fileEvents = Options(kFSEventStreamCreateFlagFileEvents)
        public static let markSelf = Options(kFSEventStreamCreateFlagMarkSelf)
    }
}

private class FSEventStreamObjCWrapper: NSObject {
    weak var swiftStream: FSEventStream?
}

private func eventStreamCallback(
    streamRef _: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard
        let clientCallBackInfo,
        let eventStream = Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(clientCallBackInfo).takeUnretainedValue().swiftStream
    else {
        return
    }

    guard let eventPaths = unsafeBitCast(eventPaths, to: CFArray.self) as? [String] else {
        return
    }

    let events = (0 ..< numEvents).compactMap { index in
        FSEvent(
            id: eventIds[index],
            path: eventPaths[index],
            flags: .init(rawValue: eventFlags[index])
        )
    }

    eventStream.callback(events)
}
