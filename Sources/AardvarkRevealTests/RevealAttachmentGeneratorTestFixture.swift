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

final class RevealAttachmentGeneratorTestFixture {

    // MARK: - Life Cycle

    init(
        revealServicePort: Int?,
        callsArchiveBuilderExpectation: XCTestExpectation? = nil
    ) {
        browser = TestServiceBrowser()
        if let port = revealServicePort {
            browser.localService = TestService(port: port)
        }

        session = TestNetworkSession()

        let archiveBuilder = TestArchiveBuilder()
        self.archiveBuilder = archiveBuilder

        dispatchQueue = DispatchQueue(label: "test")

        generator = RevealAttachmentGenerator(
            serviceBrowser: browser,
            urlSession: session,
            archiveBuilderFactory: { _ in
                callsArchiveBuilderExpectation?.fulfill()
                return archiveBuilder
            }
        )

        delegate = TestDelegate()
        generator.delegate = delegate
    }

    // MARK: - Public Properties

    let generator: RevealAttachmentGenerator

    let browser: TestServiceBrowser

    let session: TestNetworkSession

    let archiveBuilder: TestArchiveBuilder

    let delegate: TestDelegate

    let dispatchQueue: DispatchQueue

    // MARK: - Public Methods

    func triggerCapture(
        expectAttachment: Bool,
        completionExpectation: XCTestExpectation,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        generator.captureCurrentAppState(completionQueue: dispatchQueue) { [unowned self] attachment in
            dispatchPrecondition(condition: .onQueue(self.dispatchQueue))
            if expectAttachment {
                XCTAssertNotNil(attachment, file: file, line: line)
            } else {
                XCTAssertNil(attachment, file: file, line: line)
            }
            completionExpectation.fulfill()
        }
    }

    func assertCallsServiceToCaptureAppState(
        at url: String,
        responseConfig: ApplicationStateConfig?,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        XCTAssertEqual(session.tasksByRequest.count, 1, file: file, line: line)
        guard let appStateTask = session.tasksByRequest.first else {
            throw Error.expectedNetworkCall
        }
        XCTAssertEqual(appStateTask.0.url?.absoluteString, url, file: file, line: line)

        if let config = responseConfig {
            let applicationState = ApplicationState(
                screens: Screens(
                    mainScreen: Object(
                        identifier: config.mainScreenIdenitifier,
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

            appStateTask.1(try JSONEncoder().encode(applicationState))

        } else {
            appStateTask.1(nil)
        }

        // Run the run loop once to allow the async dispatch to the main queue to complete.
        RunLoop.current.run(until: Date())
    }

    func assertCallsToCaptureImage(
        at url: String,
        type: String,
        responseData: Data?,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard let task = session.tasksByRequest.first(where: { $0.0.url?.absoluteString == url }) else {
            throw Error.expectedNetworkCall
        }

        XCTAssertEqual(task.0.value(forHTTPHeaderField: "Accept"), type, file: file, line: line)

        task.1(responseData)

        // Run the run loop once to allow the async dispatch to the main queue to complete.
        RunLoop.current.run(until: Date())
    }

    // MARK: - Public Types

    enum Error: Swift.Error {
        case expectedNetworkCall
    }

    struct ApplicationStateConfig {
        var mainScreenIdenitifier: Int
    }

}

// MARK: -

final class TestServiceBrowser: RevealServiceBrowsing {

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

final class TestService: RevealService {

    // MARK: - Life Cycle

    init(port: Int = -1) {
        self.port = port
    }

    // MARK: - RevealService

    let port: Int

}

final class TestDelegate: RevealAttachmentGeneratorDelegate {

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

final class TestNetworkSession: NetworkSession {

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

final class TestArchiveBuilder: ArchiveBuilder {

    private(set) var directoryPaths: [String] = []

    func addDirectory(at path: String) throws {
        guard completeCount == 0 else { return }
        directoryPaths.append(path)
    }

    private(set) var filePaths: [String] = []

    func addFile(at path: String, with data: Data) throws {
        guard completeCount == 0 else { return }
        filePaths.append(path)
    }

    private(set) var symbolicLinks: [String: String] = [:]

    func addSymbolicLink(at path: String, to linkPath: String) throws {
        guard completeCount == 0 else { return }
        symbolicLinks[path] = linkPath
    }

    private(set) var completeCount = 0

    func completeArchive() -> Data? {
        completeCount += 1
        return Data()
    }

}
