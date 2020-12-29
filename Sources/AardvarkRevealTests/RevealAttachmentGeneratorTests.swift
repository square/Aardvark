//
//  Copyright 2020 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest

@testable import AardvarkReveal

final class RevealAttachmentGeneratorTests: XCTestCase {

    func testRevealServiceNotFound() {
        let generator = RevealAttachmentGenerator(
            serviceBrowser: TestServiceBrowser(),
            urlSession: TestNetworkSession()
        )

        let delegate = TestDelegate()
        generator.delegate = delegate

        let dispatchQueue = DispatchQueue(label: "test")
        let expectation = self.expectation(description: "calls completion")

        generator.captureCurrentAppState(completionQueue: dispatchQueue) { attachment in
            dispatchPrecondition(condition: .onQueue(dispatchQueue))
            XCTAssertNil(attachment)
            expectation.fulfill()
        }

        // The generator should never call the delegate if it couldn't find the Reveal service.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        waitForExpectations(timeout: 10)
    }

    func testFailsToCaptureAppState() {
        let session = TestNetworkSession()

        let browser = TestServiceBrowser()
        browser.localService = TestService(port: 1234)

        let generator = RevealAttachmentGenerator(
            serviceBrowser: browser,
            urlSession: session
        )

        let delegate = TestDelegate()
        generator.delegate = delegate

        let dispatchQueue = DispatchQueue(label: "test")
        let expectation = self.expectation(description: "calls completion")

        generator.captureCurrentAppState(completionQueue: dispatchQueue) { attachment in
            dispatchPrecondition(condition: .onQueue(dispatchQueue))
            XCTAssertNil(attachment)
            expectation.fulfill()
        }

        // Since the Reveal service already exists, the generator should call the delegate immediately.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The generator should immediately call the Reveal service to capture the app state.
        XCTAssertEqual(session.tasksByRequest.count, 1)
        guard let appStateTask = session.tasksByRequest.first else {
            XCTFail("Generator should have called Reveal server to capture app state")
            return
        }
        XCTAssertEqual(appStateTask.0.url?.absoluteString, "http://localhost:1234/application")

        // Simulate the task failing by calling the completion with `nil`.
        appStateTask.1(nil)

        // Run the run loop once to allow the async dispatch to the main queue to complete.
        RunLoop.current.run(until: Date())

        // The generator should still tell the delegate it has completed capturing the app state even if it fails.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        waitForExpectations(timeout: 10)
    }

    func testBuildsRevealFile() throws {
        let session = TestNetworkSession()

        let browser = TestServiceBrowser()
        browser.localService = TestService(port: 1234)

        let generator = RevealAttachmentGenerator(
            serviceBrowser: browser,
            urlSession: session
        )

        let delegate = TestDelegate()
        generator.delegate = delegate

        let dispatchQueue = DispatchQueue(label: "test")
        let expectation = self.expectation(description: "calls completion")

        generator.captureCurrentAppState(completionQueue: dispatchQueue) { attachment in
            dispatchPrecondition(condition: .onQueue(dispatchQueue))
            XCTAssertNotNil(attachment)
            expectation.fulfill()
        }

        // Since the Reveal service already exists, the generator should call the delegate immediately.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The generator should immediately call the Reveal service to capture the app state.
        XCTAssertEqual(session.tasksByRequest.count, 1)
        guard let appStateTask = session.tasksByRequest.first else {
            XCTFail("Generator should have called Reveal server to capture app state")
            return
        }
        XCTAssertEqual(appStateTask.0.url?.absoluteString, "http://localhost:1234/application")

        let applicationState = ApplicationState(
            screens: Screens(
                mainScreen: Object(
                    identifier: 5678,
                    class: .baseClass(name: "UIScreen"),
                    attributes: [:]
                )
            ),
            application: Object(
                identifier: -1,
                class: .baseClass(name: "UIApplication"),
                attributes: [:]
            )
        )

        // Simulate the task failing by calling the completion with `nil`.
        appStateTask.1(try JSONEncoder().encode(applicationState))

        // Run the run loop once to allow the async dispatch to the main queue to complete.
        RunLoop.current.run(until: Date())

        // The generator should still tell the delegate it has completed capturing the app state even if it fails.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // At this point the generator should send a request for each view, including the main screen.
        guard let mainScreenTask = session.tasksByRequest.first(where: { $0.0.url?.absoluteString.contains("5678") ?? false }) else {
            XCTFail("Generator should have sent request to capture the main screen")
            return
        }
        XCTAssertEqual(mainScreenTask.0.url?.absoluteString, "http://localhost:1234/objects/5678?subviews=1")
        XCTAssertEqual(mainScreenTask.0.value(forHTTPHeaderField: "Accept"), "image/png")

        mainScreenTask.1(Data())

        // Run the run loop once to allow the async dispatch to the main queue to complete.
        RunLoop.current.run(until: Date())

        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 1)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The last remaining task should be to fetch the app icon.
        XCTAssertEqual(session.tasksByRequest.count, 3)
        guard let iconTask = session.tasksByRequest.first(where: { $0.0.url?.absoluteString.contains("icon") ?? false }) else {
            XCTFail("Generator should have sent request to capture the app icon")
            return
        }
        XCTAssertEqual(iconTask.0.url?.absoluteString, "http://localhost:1234/icon")
        XCTAssertEqual(iconTask.0.value(forHTTPHeaderField: "Accept"), "image/tiff")

        iconTask.1(Data())

        // Run the run loop for a couple sections to allow the archive to finish building.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 1)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 1)

        waitForExpectations(timeout: 10)
    }

}

// MARK: -

private final class TestServiceBrowser: RevealServiceBrowsing {

    // MARK: - Public Properties

    var isSearching = false

    // MARK: - RevealServiceBrowsing

    var localService: RevealService?

    func startSearching() {
        isSearching = true
    }

    func stopSearching() {
        isSearching = false
    }

}

private final class TestService: RevealService {

    // MARK: - Life Cycle

    init(port: Int = -1) {
        self.port = port
    }

    // MARK: - RevealService

    let port: Int

}

private final class TestDelegate: RevealAttachmentGeneratorDelegate {

    // MARK: - RevealAttachmentGeneratorDelegate

    private(set) var willBeginCapturingAppStateCount = 0

    func revealAttachmentGeneratorWillBeginCapturingAppState() {
        willBeginCapturingAppStateCount += 1
    }

    private(set) var didFinishCapturingAppStateCount = 0
    private(set) var didFinishCapturingAppStateLastSuccess = false

    func revealAttachmentGeneratorDidFinishCapturingAppState(success: Bool) {
        didFinishCapturingAppStateCount += 1
        didFinishCapturingAppStateLastSuccess = success
    }

    private(set) var didCaptureMainScreenSnapshotCount = 0

    func revealAttachmentGeneratorDidCaptureMainScreenSnapshot() {
        didCaptureMainScreenSnapshotCount += 1
    }

    private(set) var didFinishBundlingRevealFileCount = 0

    func revealAttachmentGeneratorDidFinishBundlingRevealFile(success: Bool) {
        didFinishBundlingRevealFileCount += 1
    }

}

private final class TestNetworkSession: NetworkSession {

    // MARK: - Public Properties

    private(set) var tasksByRequest: [(URLRequest, (Data?) -> Void)] = []

    // MARK: - NetworkSession

    func performDataTask(with url: URL, completionHandler: @escaping (Data?) -> Void) {
        tasksByRequest.append((URLRequest(url: url), completionHandler))
    }

    func performDataTask(with request: URLRequest, completionHandler: @escaping (Data?) -> Void) {
        tasksByRequest.append((request, completionHandler))
    }

}
