//
//  LogStoreAttachmentGenerator.swift
//  Aardvark
//
//  Created by Nicholas Entin on 1/30/21.
//  Copyright © 2021 Square, Inc. All rights reserved.
//

import Foundation

@objc(ARKLogStoreAttachmentGenerator)
public final class LogStoreAttachmentGenerator: NSObject {

    // MARK: - Public Types

    public struct Attachments {

        public var logMessagesAttachment: ARKBugReportAttachment

        public var latestScreenshotAttachment: ARKBugReportAttachment?

    }

    // MARK: - Public Static Methods

    /// Generates bug report attachments representing the data in the log store.
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
    /// - parameter logMessages: The log messages to be included in the attachment.
    /// - parameter logFormatter: The formatter with which to format the log messages.
    /// - parameter logStoreName: The name of the log store from which the logs were collected.
    @objc(attachmentForLogMessages:usingLogFormatter:logStoreName:)
    public static func attachment(
        for logMessages: [ARKLogMessage],
        using logFormatter: ARKLogFormatter,
        logStoreName: String?
    ) -> ARKBugReportAttachment {
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
        fileName = (fileName as NSString).appendingPathExtension("png") ?? fileName
        if let logStoreName = logStoreName, !logStoreName.isEmpty {
            fileName = "\(logStoreName)_\(fileName)"
        }
        return fileName
    }

    private static func logsFileName(for logStoreName: String?, fileType: String) -> String {
        var fileName = NSLocalizedString("logs", comment: "File name for logs attachments")
        fileName = (fileName as NSString).appendingPathExtension(fileType) ?? fileName
        if let logStoreName = logStoreName, !logStoreName.isEmpty {
            fileName = "\(logStoreName)_\(fileName)"
        }
        return fileName
    }

}