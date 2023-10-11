import Foundation

#if compiler(>=5.9)

/// An AsyncSequence of `FSEvent` objects.
@available(macOS 10.15, *)
public struct FSEventAsyncStream: AsyncSequence {
    public typealias Element = [FSEvent]

    public let path: String
    public let options: FSEventStream.Options

    public init(path: String, options: FSEventStream.Options = .fileEvents) {
        self.path = path
        self.options = options
    }

    public func makeAsyncIterator() -> FSEventAsyncIterator {
        FSEventAsyncIterator(path: path, options: options)
    }

    public struct FSEventAsyncIterator: AsyncIteratorProtocol {
        private let eventStream: FSEventStream?
        private var streamIterator: AsyncStream<[FSEvent]>.Iterator

        init(path: String, options: FSEventStream.Options) {
            let (stream, continuation) = AsyncStream<[FSEvent]>.makeStream()

            eventStream = FSEventStream(path: path, options: options) { events in
                continuation.yield(events)
            }

            streamIterator = stream.makeAsyncIterator()

            if eventStream == nil {
                continuation.finish()
            }
        }

        public mutating func next() async -> [FSEvent]? {
            await streamIterator.next()
        }
    }
}

#endif
