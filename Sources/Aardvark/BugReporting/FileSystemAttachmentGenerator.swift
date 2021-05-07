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

@objc(ARKFileSystemAttachmentGenerator)
public final class FileSystemAttachmentGenerator: NSObject {

    // MARK: - Public Static Methods

    /// Generates bug report attachments showing a breakdown of the file system.
    ///
    /// The attachment consists of:
    /// * A list of files in each of the specified `searchPathDirectories` with their file size and content modification
    ///   date.
    /// * Information about the total and available capacity on the main device volume.
    ///
    /// - parameter searchPathDirectories: The search paths within the app's container that should be scanned for files.
    public static func attachment(
        searchPathDirectories: [FileManager.SearchPathDirectory] = [
            .documentDirectory,
            .applicationSupportDirectory,
            .cachesDirectory,
        ]
    ) throws -> ARKBugReportAttachment {
        enum Error: Swift.Error {
            case missingDocumentDirectory
            case missingVolumeResourceValues
        }

        let fileManager = FileManager.default

        let urls = searchPathDirectories.reduce([]) {
            $0 + fileManager.urls(for: $1, in: .userDomainMask)
        }

        var description = ""

        // We need an arbitrary URL on the main device volume in order to check the capacity and determine the URL for
        // the container. We'll use the document directory since it should always exist.
        guard let volumeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw Error.missingDocumentDirectory
        }

        let appContainerPrefixes = try self.appContainerPrefixes(for: urls.first!)

        if let primaryContainerPath = appContainerPrefixes.first {
            description += "Showing files from search paths in app container at \(primaryContainerPath)\n\n"
        }

        let propertyKeys: [URLResourceKey] = [
            .fileSizeKey,
            .contentModificationDateKey,
        ]

        let fileSizeFormatter = ByteCountFormatter()
        fileSizeFormatter.zeroPadsFractionDigits = true
        fileSizeFormatter.allowsNonnumericFormatting = false
        fileSizeFormatter.formattingContext = .listItem
        fileSizeFormatter.isAdaptive = true

        let maxPaddedFileSizeCharacterLength = 12

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = .current

        for directoryURL in urls {
            guard let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: propertyKeys
            ) else {
                continue
            }

            let directoryDisplayPath: String
            if let appContainerPrefix = appContainerPrefixes.first(where: { directoryURL.path.hasPrefix($0) }) {
                directoryDisplayPath = String(directoryURL.path.dropFirst(appContainerPrefix.count))
            } else {
                directoryDisplayPath = directoryURL.path
            }

            description += directoryDisplayPath + "\n"

            var containedFiles = false
            for case let fileURL as URL in enumerator {
                containedFiles = true

                let resourceValues = try fileURL.resourceValues(forKeys: Set(propertyKeys))

                guard let fileSize = resourceValues.fileSize else {
                    continue
                }

                let formattedFileSize = fileSizeFormatter.string(fromByteCount: Int64(fileSize))

                let formattedModifiedDate: String
                if let modifiedDate = resourceValues.contentModificationDate {
                    formattedModifiedDate = dateFormatter.string(from: modifiedDate)
                } else {
                    // This string is padded to match the length of an ISO8601 timestamp.
                    formattedModifiedDate = "(unknown)                "
                }

                let fileDisplayPath: String
                if let appContainerPrefix = appContainerPrefixes.first(where: { fileURL.path.hasPrefix($0) }) {
                    fileDisplayPath = String(fileURL.path.dropFirst(appContainerPrefix.count + directoryDisplayPath.count))
                } else {
                    fileDisplayPath = fileURL.path
                }

                let padding = String(repeating: " ", count: maxPaddedFileSizeCharacterLength - formattedFileSize.count)

                description += "\(formattedFileSize)\(padding)\(formattedModifiedDate)   \(fileDisplayPath)\n"
            }

            if !containedFiles {
                description += "(empty directory)\n"
            }

            description += "\n"
        }

        let volumeKeys: Set<URLResourceKey> = [
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey,
            .volumeTotalCapacityKey,
        ]

        let resourceValues = try volumeURL.resourceValues(forKeys: volumeKeys)

        guard
            let availableCapacity = resourceValues.volumeAvailableCapacity,
            let importantAvailableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage,
            let opportunisticAvailableCapacity = resourceValues.volumeAvailableCapacityForOpportunisticUsage,
            let totalCapacity = resourceValues.volumeTotalCapacity
        else {
            throw Error.missingVolumeResourceValues
        }

        description += """

            Available Capacity:         \(fileSizeFormatter.string(fromByteCount: Int64(availableCapacity)))
              for Important Usage:      \(fileSizeFormatter.string(fromByteCount: Int64(importantAvailableCapacity)))
              for Opportunistic Usage:  \(fileSizeFormatter.string(fromByteCount: Int64(opportunisticAvailableCapacity)))
            Total Capacity:             \(fileSizeFormatter.string(fromByteCount: Int64(totalCapacity)))

            """

        return ARKBugReportAttachment(
            fileName: "file_system.txt",
            data: Data(description.utf8),
            dataMIMEType: "text/plain"
        )
    }

    // MARK: - Private Methods

    private static func appContainerPrefixes(for directoryURL: URL) throws -> [String] {
        let path = directoryURL.path

        let uuidPattern = "[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}"

        let deviceRegex = try NSRegularExpression(
            pattern: "/var/mobile/Containers/Data/Application/(\(uuidPattern))"
        )

        if let match = deviceRegex.firstMatch(in: path, options: [], range: NSRange(location: 0, length: path.count)) {
            if let applicationIDRange = Range(match.range(at: 1), in: path) {
                let applicationID = String(path[applicationIDRange])

                // In the iOS file system, `/var` is a symlink to `/private/var`. The search path directories start with
                // `/var`, but the file enumerator returns the fully resolved path.
                return [
                    "/var/mobile/Containers/Data/Application/\(applicationID)",
                    "/private/var/mobile/Containers/Data/Application/\(applicationID)",
                ]
            }
        }

        let simulatorRegex = try NSRegularExpression(
            pattern: "/Users/([^/]+)/Library/Developer/CoreSimulator/Devices/(\(uuidPattern))/data/Containers/Data/Application/(\(uuidPattern))"
        )

        if let match = simulatorRegex.firstMatch(in: path, options: [], range: NSRange(location: 0, length: path.count)) {
            guard
                let usernameRange = Range(match.range(at: 1), in: path),
                let deviceIDRange = Range(match.range(at: 2), in: path),
                let applicationIDRange = Range(match.range(at: 3), in: path)
            else {
                return []
            }

            let username = String(path[usernameRange])
            let deviceID = String(path[deviceIDRange])
            let applicationID = String(path[applicationIDRange])

            return [
                "/Users/\(username)/Library/Developer/CoreSimulator/Devices/\(deviceID)/data/Containers/Data/Application/\(applicationID)",
            ]
        }

        return []
    }

}
