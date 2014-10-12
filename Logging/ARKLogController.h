//
//  ARKLogController.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKLogger;
@class ARKLogMessage;


@interface ARKLogController : NSObject

/// Returns the instance of the log controller used by ARKLog().
+ (instancetype)defaultController;

/// Enables logging. Defaults to NO. Turning off logging does not guarantee that logging on different threads will immediately cease. Property is atomic to support multithreaded logging.
@property (atomic, assign, readwrite) BOOL loggingEnabled;

/// Defaults to ARKLogMessage. Can be set to a subclass of ARKLogMessage. To ensure thread safety, this property can only be set once after initialization.
@property (nonatomic, assign, readwrite) Class logMessageClass;

/// The maximum number of logs allLogMessages should return. Defaults to 2000. Set to 0 to never truncate.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCount;

/// The maximum number of logs to persist to disk. Defaults to 500.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Path to the file on disk that contains peristed logs. Defaults to nil for all controllers except defaultController.
@property (nonatomic, copy, readwrite) NSString *persistedLogsFilePath;

/// Controls whether appendLogMessage: also logs to NSLog. Defaults to NO.
@property (nonatomic, assign, readwrite) BOOL logToConsole;

/// Appends a log to the logs. Non-blocking call.
- (void)appendLogMessage:(ARKLogMessage *)log;

/// Retains an object that handles logging.
- (void)addLogger:(id <ARKLogger>)logger;

/// Releases an object that handles logging.
- (void)removeLogger:(id <ARKLogger>)logger;

/// Returns an array of ARKLogMessage objects. Blocking call.
- (NSArray *)allLogMessages;

/// Removes all logs. Blocking call.
- (void)clearLogs;

@end


@interface ARKLogController (ARKLogAdditions)

/// Creates a ARKLogMessage with ARKLogTypeDefault and appends it to the logs. Non-blocking call.
- (void)appendLog:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1,0);

/// Creates a ARKLogMessage and appends it to the logs. Non-blocking call.
- (void)appendLogType:(ARKLogType)type format:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(2,0);

/// Creates a ARKLogMessage with a screenshot and appends it to the logs. Non-blocking call.
- (void)appendLogScreenshot;

@end


@interface ARKLogController (ARKLoggerAdditions)

/// Creates a ARKLogMessage with ARKLogTypeDefault and appends it to the logs. Non-blocking call.
- (void)appendLog:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/// Creates a ARKLogMessage and appends it to the logs. Non-blocking call.
- (void)appendLogType:(ARKLogType)type format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@end
