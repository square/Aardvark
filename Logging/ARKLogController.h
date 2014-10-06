//
//  ARKLogController.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKAardvarkLog;


@interface ARKLogController : NSObject

/// Returns a shared instance of the log controller.
+ (instancetype)sharedInstance;

/// The maximum number of logs allLogs should return. Defaults to 2000. Set to 0 to never truncate.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCount;

/// The maximum number of logs to persist to disk. Defaults to 500.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Appends a log to the logging queue. Non-blocking call.
- (void)appendLog:(ARKAardvarkLog *)log;

/// Returns an array of ARKAardvarkLog objects. Blocking call.
- (NSArray *)allLogs;

/// Removes all logs. Blocking call.
- (void)clearLocalLogs;

@end
