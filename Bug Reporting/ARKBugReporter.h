//
//  ARKBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKBugReporter <NSObject>

/// Kicks off composition of a bug report.
- (void)composeBugReportWithLogs:(NSArray *)logs;

@end
