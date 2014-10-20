//
//  ARKBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogController;


@protocol ARKBugReporter <NSObject>

/// Called when the user has triggered the creation of a bug report.
- (void)composeBugReport;

/// Adds logs from logControllers to future bug reports. The bug reporter should hold weak references to the logControllers.
- (void)addLogControllers:(NSArray *)logControllers;

/// Removes logs from logControllers from future bug reports.
- (void)removeLogControllers:(NSArray *)logControllers;

/// The log controllers used to generate bug reports.
- (NSArray *)logControllers;

@end
