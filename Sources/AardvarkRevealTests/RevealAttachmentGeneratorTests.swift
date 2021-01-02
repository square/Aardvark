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
        let fixture = RevealAttachmentGeneratorTestFixture(
            revealServicePort: nil
        )

        let delegate = fixture.delegate

        fixture.triggerCapture(
            expectAttachment: false,
            completionExpectation: expectation(description: "calls completion")
        )

        // The generator should never call the delegate if it couldn't find the Reveal service.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        waitForExpectations(timeout: 10)
    }

    func testFailsToCaptureAppState() throws {
        let fixture = RevealAttachmentGeneratorTestFixture(
            revealServicePort: 1234
        )

        let delegate = fixture.delegate

        fixture.triggerCapture(
            expectAttachment: false,
            completionExpectation: expectation(description: "calls completion")
        )

        // Since the Reveal service already exists, the generator should call the delegate immediately.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The generator should immediately call the Reveal service to capture the app state.
        try fixture.assertCallsServiceToCaptureAppState(
            at: "http://localhost:1234/application",
            responseConfig: nil
        )

        // The generator should still tell the delegate it has completed capturing the app state even if it fails.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        waitForExpectations(timeout: 10)
    }

    func testBuildsRevealFile() throws {
        let fixture = RevealAttachmentGeneratorTestFixture(
            revealServicePort: 1234,
            callsArchiveBuilderExpectation: expectation(description: "calls archive builder factory")
        )

        let delegate = fixture.delegate

        fixture.triggerCapture(
            expectAttachment: true,
            completionExpectation: expectation(description: "calls completion")
        )

        // Since the Reveal service already exists, the generator should call the delegate immediately.
        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 0)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The generator should immediately call the Reveal service to capture the app state.
        try fixture.assertCallsServiceToCaptureAppState(
            at: "http://localhost:1234/application",
            responseConfig: .init(
                mainScreenIdenitifier: 5678
            )
        )

        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 0)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        try fixture.assertCallsToCaptureImage(
            at: "http://localhost:1234/objects/5678?subviews=1",
            type: "image/png",
            responseData: Data()
        )

        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 1)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 0)

        // The last remaining task should be to fetch the app icon.
        try fixture.assertCallsToCaptureImage(
            at: "http://localhost:1234/icon",
            type: "image/tiff",
            responseData: Data()
        )

        // Run the run loop for a couple sections to allow the archive to finish building.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

        XCTAssertEqual(delegate.willBeginCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didFinishCapturingAppStateCount, 1)
        XCTAssertEqual(delegate.didCaptureMainScreenSnapshotCount, 1)
        XCTAssertEqual(delegate.didFinishBundlingRevealFileCount, 1)

        let archiveBuilder = fixture.archiveBuilder

        XCTAssertEqual(archiveBuilder.completeCount, 1)
        XCTAssertEqual(archiveBuilder.directoryPaths, ["Resources"])
        XCTAssertEqual(
            archiveBuilder.filePaths.sorted(),
            [
                "ApplicationState.json.gz",
                "Icon.tiff",
                "Properties.plist",
                "Resources/5678#1.png",
            ]
        )

        // There should be a single symbolic link called "Preview.png" that points at the main screen snapshot.
        XCTAssertEqual(archiveBuilder.symbolicLinks.count, 1)
        XCTAssertEqual(archiveBuilder.symbolicLinks["Preview.png"], "Resources/5678#1.png")

        waitForExpectations(timeout: 10)
    }

}
