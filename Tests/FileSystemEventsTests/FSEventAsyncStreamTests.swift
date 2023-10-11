import XCTest
@testable import FileSystemEvents

class FSEventAsyncStreamTests: XCTestCase {
    let testHelper = TestHelper(name: "\(FSEventAsyncStreamTests.self)")

    override func tearDown() {
        testHelper.deleteCreatedDirectories()
        super.tearDown()
    }

    func test_monitorUncategorizedFileSystemEvents() async throws {
        let directory = try testHelper.createTestDirectory()
        let expectation = expectation(description: #function)

        let task = Task {
            var capturedEvents: [FSEvent] = []
            for await events in FSEventAsyncStream(path: directory.path, options: .none) {
                capturedEvents.append(contentsOf: events)
                expectation.fulfill()
            }
            return capturedEvents
        }

        directory.appending(component: "fakeFile").createFile()

        await fulfillment(of: [expectation], timeout: 10)

        task.cancel()

        guard case let .success(capturedEvents) = await task.result else {
            return XCTFail("Expected task to succeed")
        }

        let event = try XCTUnwrap(capturedEvents.first)
        XCTAssertNotEqual(event.id, 0)
        XCTAssertEqual(event.path.components(separatedBy: "/").dropLast().last, directory.lastPathComponent)
        XCTAssertEqual(event.flags, .none)
        XCTAssertEqual(event.flags.debugDescription, "none")
    }

    func test_monitorFileCreation() async throws {
        let directory = try testHelper.createTestDirectory()
        let expectation = expectation(description: #function)

        let task = Task {
            var capturedEvents: [FSEvent] = []
            for await events in FSEventAsyncStream(path: directory.path) {
                capturedEvents.append(contentsOf: events)
                guard events.contains(where: { $0.path.hasSuffix("fakeFile") }) else { continue }
                expectation.fulfill()
            }
            return capturedEvents
        }

        directory.appending(component: "fakeFile").createFile(with: "fakeContent")

        await fulfillment(of: [expectation], timeout: 10)

        task.cancel()

        guard case let .success(capturedEvents) = await task.result else {
            return XCTFail("Expected task to succeed")
        }
        let event = try XCTUnwrap(capturedEvents.first { $0.path.hasSuffix("fakeFile") })
        XCTAssertNotEqual(event.id, 0)
        assert(event.flags, toContain: .isFile)
        assert(event.flags.debugDescription, toContain: "isFile")
    }
}
