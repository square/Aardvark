//
//  ARKLogController.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKAardvarkLog;
@protocol ARKLogger;


@interface ARKLogController : NSObject

///// Allocates the default controller.
//+ (void)setupDefaultController;

/// Returns a shared instance of the log controller.
+ (instancetype)defaultController;

/// Enables logging. Defaults to NO. Turning off logging does not guarantee that logging on different threads will immediately cease. Property is atomic to support multithreaded logging.
@property (atomic, assign, readwrite) BOOL loggingEnabled;

/// The maximum number of logs allLogs should return. Defaults to 2000. Set to 0 to never truncate.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCount;

/// The maximum number of logs to persist to disk. Defaults to 500.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Path to the file on disk that contains peristed logs.
@property (nonatomic, copy, readwrite) NSString *pathToPersistedLogs;

/// Controls whether appendAardvarkLog: also logs to NSLog. Defaults to NO.
@property (nonatomic, assign, readwrite) BOOL logToConsole;

/// Appends a log to the logs. Non-blocking call.
- (void)appendAardvarkLog:(ARKAardvarkLog *)log;

/// Retains an object that handles logging.
- (void)addLogger:(id <ARKLogger>)logger;

/// Releases an object that handles logging.
- (void)removeLogger:(id <ARKLogger>)logger;

/// Returns an array of ARKAardvarkLog objects. Blocking call.
- (NSArray *)allLogs;

/// Removes all logs. Blocking call.
- (void)clearLogs;

@end


@interface ARKLogController (ARKLogAdditions)

/// Creates a ARKAardvarkLog with ARKLogTypeDefault and appends it to the logs. Non-blocking call.
- (void)appendLog:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1,0);

/// Creates a ARKAardvarkLog and appends it to the logs. Non-blocking call.
- (void)appendLogType:(ARKLogType)type format:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(2,0);

/// Creates a ARKAardvarkLog with a screenshot and appends it to the logs. Non-blocking call.
- (void)appendLogScreenshot;

@end


@interface ARKLogController (ARKLoggerAdditions)

/// Creates a ARKAardvarkLog with ARKLogTypeDefault and appends it to the logs. Non-blocking call.
- (void)appendLog:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/// Creates a ARKAardvarkLog and appends it to the logs. Non-blocking call.
- (void)appendLogType:(ARKLogType)type format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@end
