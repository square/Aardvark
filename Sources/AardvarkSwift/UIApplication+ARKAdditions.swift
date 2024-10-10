//
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

import Foundation
import UIKit

extension UIApplication {

    @nonobjc
    private static var observingKeyWindowNotifications = false

    @nonobjc
    private static let bugReporterToGestureRecognizerMap: NSMapTable<ARKBugReporter, UIGestureRecognizer> = NSMapTable.strongToStrongObjects()

    /// Creates and returns a gesture recognizer that when triggered will call `bugReporter.composeBugReport()`. Must be
    /// called from the main thread.
    @nonobjc
    func add<GestureRecognizer: UIGestureRecognizer>(
        bugReporter: ARKBugReporter,
        triggeringGestureRecognizerClass: GestureRecognizer.Type
    ) -> GestureRecognizer? {
        guard Thread.isMainThread else {
            noteImproperAPIUse("Must call \(#function) from the main thread!")
            return nil
        }

        guard bugReporter.logStores().count > 0 else {
            noteImproperAPIUse("Attempting to add a bug reporter without a log store!")
            return nil
        }

        let keyWindow = connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }

        let bugReportingGestureRecognizer = triggeringGestureRecognizerClass.init(
            target: self,
            action: #selector(UIApplication.didFire(bugReportGestureRecognizer:))
        )
        keyWindow?.addGestureRecognizer(bugReportingGestureRecognizer)

        UIApplication.bugReporterToGestureRecognizerMap.setObject(bugReportingGestureRecognizer, forKey: bugReporter)

        if !UIApplication.observingKeyWindowNotifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidBecomeKey(notification:)),
                name: UIWindow.didBecomeKeyNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidResignKey(notification:)),
                name: UIWindow.didResignKeyNotification,
                object: nil
            )

            UIApplication.observingKeyWindowNotifications = true
        }

        return bugReportingGestureRecognizer
    }

    @nonobjc
    func remove(bugReporter: ARKBugReporter) {
        if let gestureRecognizerToRemove = UIApplication.bugReporterToGestureRecognizerMap.object(forKey: bugReporter) {
            gestureRecognizerToRemove.view?.removeGestureRecognizer(gestureRecognizerToRemove)

            UIApplication.bugReporterToGestureRecognizerMap.removeObject(forKey: bugReporter)
        }
    }

    @objc(ARK_didFireBugReportGestureRecognizer:)
    private func didFire(bugReportGestureRecognizer: UIGestureRecognizer) {
        guard bugReportGestureRecognizer.state == .began else {
            return
        }

        var bugReporters = [ARKBugReporter]()
        for bugReporter in UIApplication.bugReporterToGestureRecognizerMap.keyEnumerator() {
            guard
                let bugReporter = bugReporter as? ARKBugReporter,
                !bugReporters.contains(where: { $0 === bugReporter })
            else {
                continue
            }

            let recognizerForBugReport = UIApplication.bugReporterToGestureRecognizerMap.object(forKey: bugReporter)
            if recognizerForBugReport === bugReportGestureRecognizer {
                bugReporters.append(bugReporter)
            }
        }

        guard bugReporters.count > 0 else {
            return
        }

        for bugReporter in bugReporters {
            bugReporter.composeBugReport()
        }
    }

    @objc(ARK_windowDidBecomeKeyNotification:)
    private func windowDidBecomeKey(notification: Notification) {
        guard let window = notification.object as? UIWindow else {
            return
        }
        guard let enumerator = UIApplication.bugReporterToGestureRecognizerMap.objectEnumerator() else {
            return
        }

        for gestureRecognizer in enumerator {
            if let gestureRecognizer = gestureRecognizer as? UIGestureRecognizer {
                window.addGestureRecognizer(gestureRecognizer)
            }
        }
    }

    @objc(ARK_windowDidResignKeyNotification:)
    private func windowDidResignKey(notification: Notification) {
        guard let window = notification.object as? UIWindow else {
            return
        }
        guard let enumerator = UIApplication.bugReporterToGestureRecognizerMap.objectEnumerator() else {
            return
        }

        for gestureRecognizer in enumerator {
            if let gestureRecognizer = gestureRecognizer as? UIGestureRecognizer {
                window.removeGestureRecognizer(gestureRecognizer)
            }
        }
    }
}
