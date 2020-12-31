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

import Foundation

protocol ArchiveBuilder {

    func addDirectory(at path: String) throws

    func addFile(at path: String, with data: Data) throws

    func addSymbolicLink(at path: String, to linkPath: String) throws

    func completeArchive() -> Data?

}

final class ZIPArchiveBuilder: ArchiveBuilder {

    // MARK: - Life Cycle

    init(bundleName: String, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        self.temporaryContainerURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString))
        self.bundleURL = temporaryContainerURL.appendingPathComponent(bundleName, isDirectory: true)

        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
    }

    // MARK: - Private Properties

    private let temporaryContainerURL: URL

    private let bundleURL: URL

    private let fileManager: FileManager

    private var symbolicLinks: [String: String] = [:]

    // MARK: - Public Methods

    func addDirectory(at path: String) throws {
        try fileManager.createDirectory(at: bundleURL.appendingPathComponent(path), withIntermediateDirectories: true)
    }

    func addFile(at path: String, with data: Data) throws {
        try data.write(to: bundleURL.appendingPathComponent(path))
    }

    func addSymbolicLink(at path: String, to linkPath: String) throws {
        // The coordinator has trouble resolving symbolic links for some reason, so store the link paths for now, then
        // manually resolve the links when completing the archive. This is inefficient, since it duplicates data in the
        // archive, but once we figure out the issue with symbolic links we should be able to transparently switch this
        // behavior over to using real symbolic links on disk.
        symbolicLinks[path] = linkPath
    }

    func completeArchive() -> Data? {
        for (path, linkPath) in symbolicLinks {
            try? fileManager.copyItem(
                at: bundleURL.appendingPathComponent(linkPath),
                to: bundleURL.appendingPathComponent(path)
            )
        }

        let coordinator = NSFileCoordinator()

        var data: Data?
        var fileError: NSError?
        var dataError: NSError?

        coordinator.coordinate(readingItemAt: bundleURL, options: [.forUploading], error: &fileError) { archiveURL in
            do {
                data = try Data(contentsOf: archiveURL)
            } catch let readError {
                dataError = readError as NSError
            }
        }

        guard fileError == nil && dataError == nil else {
            return nil
        }

        try? fileManager.removeItem(at: temporaryContainerURL)

        return data
    }

}
