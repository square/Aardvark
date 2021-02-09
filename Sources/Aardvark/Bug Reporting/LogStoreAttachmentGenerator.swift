//
//  Copyright 2021 Square, Inc.
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

import Foundation

@objc(ARKLogStoreAttachmentGenerator)
public final class LogStoreAttachmentGenerator: NSObject {

    // MARK: - Public Types

    /// Container around the attachments generated from a log store.
    public struct Attachments {

        // An attachment representing the textual content of the log messages in the log store.
        public var logMessagesAttachment: ARKBugReportAttachment?

        // An attachment containing the image from most recent screenshot log messages in the log store.
        public var latestScreenshotAttachment: ARKBugReportAttachment?

    }

    // MARK: - Public Static Methods

    /// Generates bug report attachments representing the data in the log store.
    ///
    /// This is a convenience for asynchronously retrieving the messages from the log store and generating the
    /// appropriate attachments from those messages.
    ///
    /// - parameter logStore: The log store from which to read the messages.
    /// - parameter messageFormatter: The formatter used to format messages in the logs attachment.
    /// - parameter includeLatestScreenshot: Whether an attachment should be generated for the last screenshot in the
    /// log store, if one exists.
    /// - parameter completionQueue: The queue on which the completion should be called.
    /// - parameter completion: The completion to be called once the attachments have been generated.
    public static func attachments(
        for logStore: ARKLogStore,
        messageFormatter: ARKLogFormatter = ARKDefaultLogFormatter(),
        includeLatestScreenshot: Bool,
        completionQueue: DispatchQueue,
        completion: @escaping (Attachments) -> Void
    ) {
        logStore.retrieveAllLogMessages { logMessages in
            let screenshotAttachment: ARKBugReportAttachment?
            if includeLatestScreenshot {
                screenshotAttachment = attachmentForLatestScreenshot(in: logMessages, logStoreName: logStore.name)
            } else {
                screenshotAttachment = nil
            }

            let logsAttachment = attachment(
                for: logMessages,
                using: messageFormatter,
                logStoreName: logStore.name
            )

            completionQueue.async {
                completion(
                    .init(
                        logMessagesAttachment: logsAttachment,
                        latestScreenshotAttachment: screenshotAttachment
                    )
                )
            }
        }
    }

    /// Generates an attachment containing the latest screenshot in the provided log messages.
    ///
    /// - parameter logMessages: The log messages through which to search for the screenshot.
    /// - parameter logStoreName: The name of the log store from which the logs were collected.
    @objc(attachmentForLatestScreenshotInLogMessages:logStoreName:)
    public static func attachmentForLatestScreenshot(
        in logMessages: [ARKLogMessage],
        logStoreName: String?
    ) -> ARKBugReportAttachment? {
        guard
            let screenshotMessage = logMessages.reversed().first(where: { $0.type == .screenshot }),
            let imageData = screenshotMessage.image?.pngData()
        else {
            return nil
        }

        return ARKBugReportAttachment(
            fileName: screenshotFileName(for: logStoreName),
            data: imageData,
            dataMIMEType: "image/png"
        )
    }

    /// Generates an attachment containing the log messages formatted using the specified formatter.
    ///
    /// Returns `nil` if there are no log messages.
    ///
    /// - parameter logMessages: The log messages to be included in the attachment.
    /// - parameter logFormatter: The formatter with which to format the log messages.
    /// - parameter logStoreName: The name of the log store from which the logs were collected.
    @objc(attachmentForLogMessages:usingLogFormatter:logStoreName:)
    public static func attachment(
        for logMessages: [ARKLogMessage],
        using logFormatter: ARKLogFormatter = ARKDefaultLogFormatter(),
        logStoreName: String?
    ) -> ARKBugReportAttachment? {
        guard !logMessages.isEmpty else {
            return nil
        }

        let formattedLogData = logMessages
            .map(logFormatter.formattedLogMessage(_:))
            .joined(separator: "\n")
            .data(using: .utf8)!

        let fileName = logsFileName(for: logStoreName, fileType: "txt")

        return ARKBugReportAttachment(
            fileName: fileName,
            data: formattedLogData,
            dataMIMEType: "text/plain"
        )
    }

    // MARK: - Private Static Methods

    private static func screenshotFileName(for logStoreName: String?) -> String {
        var fileName = NSLocalizedString("screenshot", comment: "File name of a screenshot")
        fileName = URL(fileURLWithPath: fileName).appendingPathExtension("png").lastPathComponent
        if let logStoreName = logStoreName, !logStoreName.isEmpty {
            fileName = "\(logStoreName)_\(fileName)"
        }
        return fileName
    }

    private static func logsFileName(for logStoreName: String?, fileType: String) -> String {
        var fileName = NSLocalizedString("logs", comment: "File name for logs attachments")
        fileName = URL(fileURLWithPath: fileName).appendingPathExtension(fileType).lastPathComponent
        if let logStoreName = logStoreName, !logStoreName.isEmpty {
            fileName = "\(logStoreName)_\(fileName)"
        }
        return fileName
    }

}
