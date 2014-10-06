//
//  ARKLogController.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKAardvarkLog;
@class ARKEmailBugReporter;


@interface ARKLogController : NSObject <UIActivityItemSource>

+ (instancetype)sharedInstance;

/// The bug reporting object to handle bug reporting. Must be set before installScreenshotGestureRecognizer is called.
@property (nonatomic, strong, readwrite) ARKEmailBugReporter *bugReporter;

/// The maximum number of logs allLogs should return. Defaults to 2000. Set to 0 to never truncate.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCount;

/// The maximum number of logs to persist to disk. Defaults to 500.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Installs a two-finger long press gesture recognizer. When the gesture recognizer is triggered, a screenshot is taken and the bugReporter is told to compose a bug report.
- (void)installScreenshotGestureRecognizer;

/// Uninstalls the two-finger long press gesture recognizer.
- (void)uninstallScreenshotGestureRecognizer;

/// Appends a log ot the logging queue. Non-blocking call.
- (void)appendLog:(ARKAardvarkLog *)log;

/// Returns an array of ARKAardvarkLog objects. Blocking call.
- (NSArray *)allLogs;

/// Removes all logs. Blocking call.
- (void)clearLocalLogs;

@end
