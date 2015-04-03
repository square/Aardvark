//
//  ARKBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright 2014 Square, Inc.
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

@protocol ARKBugReporter <NSObject>

/// Called when the user has triggered the creation of a bug report.
- (void)composeBugReport;

/// Add logs from logStores to future bug reports.
- (void)addLogStores:(NSArray *)logStores;

/// Remove logs from logStores from future bug reports.
- (void)removeLogStores:(NSArray *)logStores;

/// The log stores used to generate bug reports.
- (NSArray *)logStores;

@end
