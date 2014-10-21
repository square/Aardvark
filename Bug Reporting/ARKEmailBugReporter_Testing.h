//
//  ARKEmailBugReporter_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 10/20/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKEmailBugReporter ()

- (NSString *)_recentErrorLogMessagesAsPlainText:(NSArray *)logMessages count:(NSUInteger)errorLogsToInclude;

@end
