import XCTest
@testable import FileSystemEvents

class FSEventStreamTests: XCTestCase {
    let testHelper = TestHelper(name: "\(FSEventStreamTests.self)")

    override func tearDown() {
        testHelper.deleteCreatedDirectories()
        super.tearDown()
    }

    func test_monitorUncategorizedFileSystemEvents() throws {
        let directory = try testHelper.createTestDirectory()
        let expectation = expectation(description: #function)

        var capturedEvents: [FSEvent] = []
        let stream = FSEventStream(path: directory.path, options: .none) { events in
            capturedEvents.append(contentsOf: events)
            expectation.fulfill()
        }
        XCTAssertNotNil(stream)

        directory.appending(component: "fakeFile").createFile()
        wait(for: [expectation], timeout: 10)

        let event = try XCTUnwrap(capturedEvents.first)
        XCTAssertNotEqual(event.id, 0)
        XCTAssertEqual(event.path.components(separatedBy: "/").dropLast().last, directory.lastPathComponent)
        XCTAssertEqual(event.flags, .none)
        XCTAssertEqual(event.flags.debugDescription, "none")
    }

    func test_monitorFileCreation() throws {
        let directory = try testHelper.createTestDirectory()
        let expectation = expectation(description: #function)

        var capturedEvents: [FSEvent] = []
        let stream = try XCTUnwrap(FSEventStream(path: directory.path) { events in
            capturedEvents.append(contentsOf: events)
            guard events.contains(where: { $0.path.hasSuffix("fakeFile") }) else { return }
            expectation.fulfill()
        })
        XCTAssertNotNil(stream)

        directory.appending(component: "fakeFile").createFile(with: "fakeContent")
        wait(for: [expectation], timeout: 10)

        let event = try XCTUnwrap(capturedEvents.first { $0.path.hasSuffix("fakeFile") })
        XCTAssertNotEqual(event.id, 0)
        assert(event.flags, toContain: .isFile)
        assert(event.flags.debugDescription, toContain: "isFile")
    }
}
