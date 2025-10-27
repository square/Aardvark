//
//  Copyright 2023 Block, Inc.
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

#if SWIFT_PACKAGE
import Aardvark
#endif

import Foundation

@objc(ARKDictionaryrAttachmentGenerator)
public final class DictionaryAttachmentGenerator: NSObject {

    /// Generates a plist attachment containing key-value pairs.
    ///
    /// - parameter keyValueStore: A dictionary representing the key-value store from which the attachment will be created.
    /// - parameter includedKeys: An optional list of keys. If provided, only the key-value pairs with keys in this list will be included in the attachment. If not, all key-value pairs from the `keyValueStore` will be included.
    /// - parameter fileName: An optional file name for the attachment, without the file extension.
    public static func attachment(
        for keyValueStore: [String: Any],
        includedKeys keys: [String]? = nil,
        named fileName: String
    ) throws -> ARKBugReportAttachment {
        let plistDictionary: [String: Any]
        if let keys = keys {
            // If a list of keys was provided, filter the dictionary to only include those keys.
            plistDictionary = keyValueStore.filter { keys.contains($0.key) }
        } else {
            plistDictionary = keyValueStore
        }

        // Write the dictionary to disk in order to get a Plist representation.
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try (plistDictionary as NSDictionary).write(to: temporaryURL)

        return ARKBugReportAttachment(
            fileName: "\(fileName).plist",
            data: try Data(contentsOf: temporaryURL),
            dataMIMEType: "text/xml"
        )
    }

}
