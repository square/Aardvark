//
//  ARKBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
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
