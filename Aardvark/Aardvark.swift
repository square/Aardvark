//
//  Aardvark.swift
//  Aardvark
//
//  Created by Dan Federman on 3/23/16.
//  Copyright © 2016 Square, Inc.
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

import CoreAardvark
import Foundation


public typealias EmailAddress = String

@objc public class Aardvark : NSObject {
    
    /// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to emailAddress. Returns the created bug reporter for convenience.
    @objc
    public static func addDefaultBugReportingGestureWithEmailBugReporter(withRecipient emailAddress: EmailAddress) -> ARKEmailBugReporter {
        let logStore = ARKLogDistributor.default().defaultLogStore
        let bugReporter = ARKEmailBugReporter(emailAddress: emailAddress, logStore: logStore)
        
        UIApplication.shared.addTwoFingerPressAndHoldGestureRecognizerTrigger(with: bugReporter)
        
        return bugReporter;
    }
    
    /// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
    @nonobjc public static func add<GestureRecognizer: UIGestureRecognizer>(bugReporter: ARKBugReporter, triggeringGestureRecognizerClass: GestureRecognizer.Type) -> GestureRecognizer? {
        return UIApplication.shared.add(bugReporter: bugReporter, triggeringGestureRecognizerClass: triggeringGestureRecognizerClass)
    }
    
    /// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
    @objc(addBugReporter:gestureRecognizerClass:) public static func objc_add(bugReporter: ARKBugReporter, triggeringGestureRecognizerClass gestureRecognizerClass: AnyClass) -> AnyObject? {
        guard let triggeringGestureRecognizerClass = gestureRecognizerClass as? UIGestureRecognizer.Type else {
            noteImproperAPIUse("\(gestureRecognizerClass) is not a gesture recognizer class!")
            return nil
        }
        
        return UIApplication.shared.add(bugReporter: bugReporter, triggeringGestureRecognizerClass: triggeringGestureRecognizerClass)
    }
}

func noteImproperAPIUse(_ message: String) {
    do {
        throw NSError(domain: "ARKImproperAPIUsageDomain", code: 0, userInfo: nil)
    } catch _ {
        NSLog(message)
    }
}
