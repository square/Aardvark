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

import CoreAardvark

@objc public protocol ARKBugReporter: NSObjectProtocol {

    /// Called when the user has triggered the creation of a bug report, including a screenshot attached to the report.
    func composeBugReport()

    /// Called when the user has triggered the creation of a bug report, without an attachment screenshot.
    func composeBugReportWithoutScreenshot()

    /// Add logs from `logStores` to future bug reports.
    @objc(addLogStores:)
    func add(logStores: [ARKLogStore])

    /// Remove logs from `logStores` from future bug reports.
    @objc(removeLogStores:)
    func remove(logStores: [ARKLogStore])

    /// The log stores used to generate bug reports.
    func logStores() -> [ARKLogStore]

}
