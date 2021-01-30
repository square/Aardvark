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

    /// Generates bug report attachments representing the data in the log store.
    ///
    /// - parameter includeLatestScreenshot: Whether an attachment should be generated for the last screenshot
    /// in the log store, if one exists.
    @objc
    public static func attachments(
        for logStore: ARKLogStore,
        messageFormatter: ARKLogFormatter = ARKDefaultLogFormatter(),
        includeLatestScreenshot: Bool,
        completionQueue: DispatchQueue,
        completion: @escaping ([ARKBugReportAttachment]) -> Void
    ) {
        logStore.retrieveAllLogMessages { logMessages in
            let attachments = Self.attachments(
                for: logMessages,
                logStoreName: logStore.name,
                messageFormatter: messageFormatter,
                includeLatestScreenshot: includeLatestScreenshot
            )

            completionQueue.async {
                completion(attachments)
            }
        }
    }

    /// Generates bug report attachments representing the log messages.
    ///
    /// - parameter includeLatestScreenshot: Whether an attachment should be generated for the last screenshot
    /// in the log messages, if one exists.
    @objc
    public static func attachments(
        for logMessages: [ARKLogMessage],
        logStoreName: String?,
        messageFormatter: ARKLogFormatter = ARKDefaultLogFormatter(),
        includeLatestScreenshot: Bool
    ) -> [ARKBugReportAttachment] {
        var attachments: [ARKBugReportAttachment] = []

        if includeLatestScreenshot, let attachment = attachmentForLatestScreenshot(in: logMessages, logStoreName: logStoreName) {
            attachments.append(attachment)
        }

        let logsAttachment = attachmentForLogs(for: logMessages, using: messageFormatter, logStoreName: logStoreName)
        attachments.append(logsAttachment)

        return attachments
    }

    // MARK: - Private Methods

    private static func attachmentForLatestScreenshot(
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

    private static func screenshotFileName(for logStoreName: String?) -> String {
        var fileName = NSLocalizedString("screenshot", comment: "File name of a screenshot")
        fileName = (fileName as NSString).appendingPathExtension("png") ?? fileName
        if let logStoreName = logStoreName, !logStoreName.isEmpty {
            fileName = "\(logStoreName)_\(fileName)"
        }
        return fileName
    }

    private static func attachmentForLogs(
        for logMessages: [ARKLogMessage],
        using logFormatter: ARKLogFormatter,
        logStoreName: String?
    ) -> ARKBugReportAttachment {
        let formattedLogData = logMessages
            .map(logFormatter.formattedLogMessage(_:))
            .joined(separator: "\n")
            .data(using: .utf8)!

        return ARKBugReportAttachment(
            fileName: logsFileName(for: logStoreName, fileType: "txt"),
            data: formattedLogData,
            dataMIMEType: "text/plain"
        )
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
