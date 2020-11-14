//
//  AppDelegate.swift
//  AardvarkSample
//
//  Created by Dan Federman on 9/21/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
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
import AardvarkMailUI
import AardvarkReveal
import CoreAardvark
import UIKit


@UIApplicationMain
class SampleAppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Public Properties

    var window: UIWindow?
    var bugReporter: ARKBugReporter?
    var revealAttachmentGenerator: RevealAttachmentGenerator?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // This line is all you'll need to get started.
        bugReporter = Aardvark.addDefaultBugReportingGestureWithEmailBugReporter(withRecipient: "fake-email@aardvarkbugreporting.src")

        // Log all log messages to Crashlytics to help debug crashes.
        ARKLogDistributor.default().add(SampleCrashlyticsLogObserver())

        // We'll also set up a three finger gesture to show how filing a bug report with a Reveal attachment works.
        setUpRevealBugReportGesture()
        
        log("Hello World", type: .separator)
        
        NSSetUncaughtExceptionHandler(existingUncaughtExceptionHandler)
        
        ARKEnableLogOnUncaughtException()
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        log("\(#function)")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        log("\(#function)")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        log("\(#function)", type: .error)
    }

    // MARK: - Private Methods

    private func setUpRevealBugReportGesture() {
        let revealAttachmentGenerator = RevealAttachmentGenerator()
        self.revealAttachmentGenerator = revealAttachmentGenerator

        let bugReporter = ARKEmailBugReporter(
            emailAddress: "fake-email@aardvarkbugreporting.src",
            logStore: ARKLogDistributor.default().defaultLogStore
        )

        // In order to include the Reveal attachment, we'll use a custom prompt that is delayed until the attachment has
        // been generated.
        bugReporter.promptingDelegate = self

        let gestureRecognizer = Aardvark.add(
            bugReporter: bugReporter,
            triggeringGestureRecognizerClass: UILongPressGestureRecognizer.self
        )
        gestureRecognizer?.numberOfTouchesRequired = 3
    }

}

// MARK: - Uncaught Exception Handling

func existingUncaughtExceptionHandler(exception: NSException) {
    print("Existing uncaught exception handler got called for exception: \(exception)")
}

// MARK: -

extension SampleAppDelegate: ARKEmailBugReporterPromptingDelegate {

    func showBugReportingPrompt(
        for configuration: ARKEmailBugReportConfiguration,
        completion: @escaping ARKEmailBugReporterCustomPromptCompletionBlock
    ) {
        UIApplication.shared.beginIgnoringInteractionEvents()

        revealAttachmentGenerator?.captureCurrentAppState(completionQueue: .main) { attachment in
            UIApplication.shared.endIgnoringInteractionEvents()

            if let attachment = attachment {
                configuration.additionalAttachments.append(attachment)
            }

            self.presentPrompt(for: configuration, completion: completion)
        }
    }

    private func presentPrompt(
        for configuration: ARKEmailBugReportConfiguration,
        completion: @escaping ARKEmailBugReporterCustomPromptCompletionBlock
    ) {
        let alertController = UIAlertController(
            title: "What Went Wrong?",
            message: "Please breifly summarize the issue you just encountered. You’ll be asked for more details later.",
            preferredStyle: .alert
        )

        alertController.addAction(
            .init(
                title: "Compose Report",
                style: .default,
                handler: { _ in
                    if let textField = alertController.textFields?.first {
                        configuration.prefilledEmailSubject = textField.text ?? ""
                    }
                    completion(configuration)
                }
            )
        )

        alertController.addAction(
            .init(
                title: "Cancel",
                style: .cancel,
                handler: { _ in
                    completion(nil)
                }
            )
        )

        alertController.addTextField { textField in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.spellCheckingType = .yes
            textField.returnKeyType = .done
        }

        window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

}
