//
//  ARKLogStore.h
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogObserver.h>


/// Posting this notification triggers the owning log distributor to immediately distribute pending logs to the observer.
extern NSString *const ARKLogObserverRequiresAllPendingLogsNotification;


/// Stores log messages locally for use in bug reports. All methods and properties on this class are threadsafe.
@interface ARKLogStore : NSObject <ARKLogObserver>

/// Creates an ARKLogStore with persistedLogsFileURL set to the supplied fileName within the application support directory.
- (instancetype)initWithPersistedLogFileName:(NSString *)fileName;

/// Convenience property that allows bug reporters to prefix logs with the name of the store they came from. Defaults to nil. Accessor blocks on logging queue; setter is non-blocking.
@property (nonatomic, copy, readwrite) NSString *name;

/// The maximum number of logs allLogMessages should return. Defaults to 2000. Old messages are purged once this limit is hit. Accessor blocks on logging queue; setter is non-blocking.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogMessageCount;

/// The maximum number of logs to persist to disk. Defaults to 500. Accessor blocks on log distributing queue; setter is non-blocking.
@property (nonatomic, assign, readwrite) NSUInteger maximumLogCountToPersist;

/// Path to the file on disk that contains peristed logs. Defaults to nil. Accessor blocks on log distributing queue; setter is non-blocking.
@property (nonatomic, copy, readwrite) NSURL *persistedLogsFileURL;

/// Controls whether consuming logs also outputs to NSLog. Defaults to NO. Accessor blocks on log distributing queue; setter is non-blocking.
@property (nonatomic, assign, readwrite) BOOL logsToConsole;

/// Block that allows for filtering logs. Return YES if the receiver should observe the supplied log.
@property (nonatomic, copy, readwrite) BOOL (^logFilterBlock)(ARKLogMessage *logMessage);

/// Returns an array of ARKLogMessage objects. Blocks on log distributing queue.
- (NSArray *)allLogMessages;

/// Removes all logs. Non-blocking call.
- (void)clearLogs;

@end
