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

final class FileSystemAttachmentGeneratorTests: XCTestCase {

    func testAttachment() throws {
        enum Error: Swift.Error {
            case invalidTimeZone
        }

        guard let timeZone = TimeZone(secondsFromGMT: -8 * 60 * 60) else {
            throw Error.invalidTimeZone
        }

        let containerPath = NSTemporaryDirectory()
        let fileManager = try TestFileManager(containerPath: containerPath)

        let attachment = try FileSystemAttachmentGenerator.attachment(
            searchPathDirectories: [.applicationSupportDirectory, .documentDirectory],
            fileManager: fileManager,
            timeZone: timeZone
        )

        XCTAssertEqual(
            String(data: attachment.data, encoding: .utf8),
            """
            Showing files from search paths in app container at \(containerPath.dropLast(1))

            /application-support
            11 bytes    1969-12-31T16:00:10-08:00   /test.txt

            /documents
            (empty directory)


            Available Capacity:         1.00 GB
              for Important Usage:      1.10 GB
              for Opportunistic Usage:  900.0 MB
            Total Capacity:             16.00 GB

            """
        )
    }

}

// MARK: -

final class TestFileManager: FileManaging {

    // MARK: - Life Cycle

    init(containerPath: String) throws {
        let containerURL = URL(fileURLWithPath: containerPath)

        applicationSupportDirectoryURL = containerURL.appendingPathComponent("application-support")
        try realFileManager.createDirectory(at: applicationSupportDirectoryURL, withIntermediateDirectories: true)

        documentDirectoryURL = containerURL.appendingPathComponent("documents")
        try realFileManager.createDirectory(at: documentDirectoryURL, withIntermediateDirectories: true)

        let fileURL = applicationSupportDirectoryURL.appendingPathComponent("test.txt")
        try "Hello world".data(using: .utf8)?.write(to: fileURL)
        try realFileManager.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 10)],
            ofItemAtPath: fileURL.path
        )
    }

    deinit {
        try? realFileManager.removeItem(at: applicationSupportDirectoryURL)
        try? realFileManager.removeItem(at: documentDirectoryURL)
    }

    // MARK: - Private Properties

    private let realFileManager: FileManager = .default

    private let applicationSupportDirectoryURL: URL

    private let documentDirectoryURL: URL

    // MARK: - FileManaging

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        switch directory {
        case .applicationSupportDirectory:
            return [applicationSupportDirectoryURL]
        case .documentDirectory:
            return [documentDirectoryURL]
        default:
            XCTFail("Unexpected search path directory")
            return []
        }
    }

    func enumerator(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions,
        errorHandler handler: ((URL, Error) -> Bool)?
    ) -> FileManager.DirectoryEnumerator? {
        return realFileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: mask,
            errorHandler: handler
        )
    }

    func volumeResourceValues(for url: URL) throws -> VolumeResourceValues {
        return VolumeResourceValues(
            availableCapacity: 1_000_000_000,
            importantAvailableCapacity: 1_100_000_000,
            opportunisticAvailableCapacity: 0_900_000_000,
            totalCapacity: 16_000_000_000
        )
    }

}
