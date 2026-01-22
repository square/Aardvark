//
//  Copyright © 2020 Square, Inc.
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

import Aardvark

#if SWIFT_PACKAGE
import AardvarkSwift
import AardvarkMailUI

/// Re-export the Aardvark class so consumers can use `Aardvark.methodName()` syntax
public typealias Aardvark = AardvarkSwift.Aardvark
#endif

extension Aardvark {

    /// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to
    /// `emailAddress`. Returns the created bug reporter for convenience.
    @objc
    public static func addDefaultBugReportingGestureWithEmailBugReporter(
        withRecipient emailAddress: String
    ) -> ARKEmailBugReporter {
        let logStore = ARKLogDistributor.default().defaultLogStore
        let bugReporter = ARKEmailBugReporter(emailAddress: emailAddress, logStore: logStore)

        let gestureRecognizer = Self.add(
            bugReporter: bugReporter,
            triggeringGestureRecognizerClass: UILongPressGestureRecognizer.self
        )
        gestureRecognizer?.numberOfTouchesRequired = 2

        return bugReporter
    }

}
