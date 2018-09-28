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
import CoreAardvark
import UIKit


@UIApplicationMain
class SampleAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var bugReporter: ARKBugReporter?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // This line is all you'll need to get started.
        bugReporter = Aardvark.addDefaultBugReportingGestureWithEmailBugReporter(withRecipient: "fake-email@aardvarkbugreporting.src")
        
        // Log all log messages to Crashlytics to help debug crashes.
        ARKLogDistributor.default().add(SampleCrashlyticsLogObserver())
        
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

}

// MARK: - Uncaught Exception Handling

func existingUncaughtExceptionHandler(exception: NSException) {
    print("Existing uncaught exception handler got called")
}
