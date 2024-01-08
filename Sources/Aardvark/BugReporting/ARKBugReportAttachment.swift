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

public final class ARKBugReportAttachment: NSObject {

    // MARK: - Life Cycle

    @objc public init(
        fileName: String,
        data: Data,
        dataMIMEType: String,
        highlightsSummary: String? = nil
    ) {
        self.fileName = fileName
        self.data = data
        self.dataMIMEType = dataMIMEType
        self.highlightsSummary = highlightsSummary
    }

    // MARK: - Public Properties

    /// File name (including extension) to use when attaching to the email.
    ///
    /// The file name does not need to be unique among attachments, but should not be empty.
    @objc public let fileName: String

    /// Contents of the attachment.
    ///
    /// Attachments with empty data will be dropped.
    @objc public let data: Data

    /// MIME type of the `data` property.
    ///
    /// MIME types are as specified by the IANA: <http://www.iana.org/assignments/media-types/>.
    @objc public let dataMIMEType: String

    @objc public let highlightsSummary: String?

}
