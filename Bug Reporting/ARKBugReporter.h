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

/// Bug reports composed after calling this method will include logs from logController. The bug reporter should hold a weak reference to logController.
- (void)addLogController:(ARKLogController *)logController;

/// Bug reports composed after calling this method will not include logs from logController.
- (void)removeLogController:(ARKLogController *)logController;

@end
