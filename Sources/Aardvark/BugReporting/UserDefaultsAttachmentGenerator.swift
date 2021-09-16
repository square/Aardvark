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

@objc(ARKUserDefaultsAttachmentGenerator)
public final class UserDefaultsAttachmentGenerator: NSObject {

    /// Generates an attachment containing a representation of the data in the specified user defaults store.
    ///
    /// - parameter userDefaults: The user defaults store from which to pull data.
    /// - parameter fileName: An optional file name for the attachment, without the file extension.
    public static func attachment(
        for userDefaults: UserDefaults = .standard,
        named fileName: String? = nil
    ) throws -> ARKBugReportAttachment {
        let userDefaultsDictionary = userDefaults.dictionaryRepresentation()

        // Write the dictionary to disk in order to get a Plist representation.
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try (userDefaultsDictionary as NSDictionary).write(to: temporaryURL)

        return ARKBugReportAttachment(
            fileName: (fileName ?? "user_defaults") + ".plist",
            data: try Data(contentsOf: temporaryURL),
            dataMIMEType: "text/xml"
        )
    }

}
