//
//  Copyright © 2021 Square, Inc.
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

@testable import Aardvark

final class LogStoreAttachmentGeneratorTests: XCTestCase {

    // MARK: - Tests - Log Messages Attachment

    func testLogMessageAttachmentIsNilWhenEmpty() {
        XCTAssertNil(LogStoreAttachmentGenerator.attachment(for: [], logStoreName: "test"))
    }

    func testLogMessageAttachmentContainsFormattedMessages() throws {
        let logMessages = [
            ARKLogMessage(text: "Message A", image: nil, type: .default, parameters: [:], userInfo: nil),
            ARKLogMessage(text: "Message B", image: nil, type: .default, parameters: [:], userInfo: nil),
            ARKLogMessage(text: "Message C", image: nil, type: .default, parameters: [:], userInfo: nil),
        ]

        let attachment = try XCTUnwrap(
            LogStoreAttachmentGenerator.attachment(for: logMessages, using: TestFormatter(), logStoreName: nil)
        )

        XCTAssertEqual(
            String(data: attachment.data, encoding: .utf8),
            """
            Message A
            Message B
            Message C
            """
        )

        XCTAssertEqual(attachment.dataMIMEType, "text/plain")
    }

    func testLogMessageAttachmentName() throws {
        let logMessages = [
            ARKLogMessage(text: "Message", image: nil, type: .default, parameters: [:], userInfo: nil),
        ]

        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachment(for: logMessages, logStoreName: nil)?.fileName,
            "logs.txt"
        )
        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachment(for: logMessages, logStoreName: "")?.fileName,
            "logs.txt"
        )
        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachment(for: logMessages, logStoreName: "Test")?.fileName,
            "Test_logs.txt"
        )
    }

    // MARK: - Tests - Screenshot Attachment

    func testScreenshotAttachmentName() throws {
        let logMessages = [
            ARKLogMessage(text: "Message", image: Factory.fakeScreenshotImage, type: .screenshot, parameters: [:], userInfo: nil),
        ]

        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachmentForLatestScreenshot(in: logMessages, logStoreName: nil)?.fileName,
            "screenshot.png"
        )
        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachmentForLatestScreenshot(in: logMessages, logStoreName: "")?.fileName,
            "screenshot.png"
        )
        XCTAssertEqual(
            LogStoreAttachmentGenerator.attachmentForLatestScreenshot(in: logMessages, logStoreName: "Test")?.fileName,
            "Test_screenshot.png"
        )
    }

}

// MARK: -

private final class TestFormatter: NSObject, ARKLogFormatter {

    func formattedLogMessage(_ logMessage: ARKLogMessage) -> String {
        return logMessage.text
    }

}

// MARK: -

private enum Factory {

    static let fakeScreenshotImage: UIImage = {
        let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        view.backgroundColor = .black

        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }()

}
