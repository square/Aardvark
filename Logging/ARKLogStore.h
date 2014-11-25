//
//  ARKLogStore.h
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogObserver.h>


/// Stores log messages locally for use in bug reports. All methods and properties on this class are threadsafe.
@interface ARKLogStore : NSObject <ARKLogObserver>

/// Creates an ARKLogStore with persistedLogsFileURL set to the supplied fileName within the application support directory.
- (instancetype)initWithPersistedLogFileName:(NSString *)fileName;

/// Convenience property that allows bug reporters to prefix logs with the name of the store they came from. Defaults to nil.
@property (atomic, copy, readwrite) NSString *name;

/// The maximum number of logs retrieveAllLogMessagesWithCompletionHandler: should return. Defaults to 2000. Old messages are purged once this limit is hit.
@property (atomic, assign, readwrite) NSUInteger maximumLogMessageCount;

/// The maximum number of logs to persist to disk. Defaults to 500.
@property (atomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Path to the file on disk that contains peristed logs. Defaults to nil.
@property (atomic, copy, readwrite) NSURL *persistedLogsFileURL;

/// Controls whether consuming logs also outputs to NSLog. Defaults to NO.
@property (atomic, assign, readwrite) BOOL logsToConsole;

/// Block that allows for filtering logs. Return YES if the receiver should observe the supplied log.
@property (atomic, copy, readwrite) BOOL (^logFilterBlock)(ARKLogMessage *logMessage);

/// Retrieves an array of ARKLogMessage objects. Completion handler is called on the calling queue, or the main queue if the calling queue can not be determined.
- (void)retrieveAllLogMessagesWithCompletionHandler:(void (^)(NSArray *logMessages))completionHandler;

/// Removes all logs.
- (void)clearLogs;

@end
