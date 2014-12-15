//
//  ARKLogTableViewController_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 12/15/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogMessage.h"


@interface ARKLogTableViewController (Private)

@property (nonatomic, copy, readonly) NSArray *logMessages;

- (void)_reloadLogs;

@end


@interface ARKTimestampLogMessage : ARKLogMessage

- (instancetype)initWithDate:(NSDate *)date;

@end
