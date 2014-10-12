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

@end
