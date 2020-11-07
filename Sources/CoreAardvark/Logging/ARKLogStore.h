//
//  ARKLogStore.h
//  CoreAardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright 2014 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <CoreAardvark/ARKLogObserver.h>


/// Stores log messages locally for use in bug reports. All methods and properties on this class are threadsafe.
@interface ARKLogStore : NSObject <ARKLogObserver>

/// Creates an ARKLogStore with persistedLogFileURL set to the supplied fileName within the application support directory and a maximumLogMessageCount of logs to persist.
- (nullable instancetype)initWithPersistedLogFileName:(nonnull NSString *)fileName maximumLogMessageCount:(NSUInteger)maximumLogMessageCount NS_DESIGNATED_INITIALIZER;

/// Creates an ARKLogStore with persistedLogsFileURL set to the supplied fileName within the application support directory that keeps a maximum of 2000 logs persisted.
- (nullable instancetype)initWithPersistedLogFileName:(nonnull NSString *)fileName;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

/// Path to the file on disk that contains peristed logs.
@property (nonnull, nonatomic, copy, readonly) NSURL *persistedLogFileURL;

/// The maximum number of logs retrieveAllLogMessagesWithCompletionHandler: should return. Old messages are trimmed once this limit is hit.
@property (nonatomic, readonly) NSUInteger maximumLogMessageCount;

/// Convenience property that allows bug reporters to prefix logs with the name of the store they came from. Defaults to nil.
@property (atomic, nonnull, copy) NSString *name;

/// Controls whether consuming logs also outputs to NSLog. Defaults to NO.
@property (atomic) BOOL printsLogsToConsole;

/// Controls whether, when printing logs to the console, the name of the log store is included. Defaults to YES.
@property (atomic) BOOL prefixNameWhenPrintingToConsole;

/// Block that allows for filtering logs. Return YES if the receiver should observe the supplied log.
@property (nullable, atomic, copy) BOOL (^logFilterBlock)(ARKLogMessage * _Nonnull logMessage);

/// Retrieves an array of ARKLogMessage objects. Completion handler is called on the main queue.
- (void)retrieveAllLogMessagesWithCompletionHandler:(nonnull void (^)(NSArray * _Nonnull logMessages))completionHandler;

/// Removes all logs. Completion handler is called on the main queue.
- (void)clearLogsWithCompletionHandler:(nullable dispatch_block_t)completionHandler;

/// Waits for all of the pending logs to distribute from the log distributor, then saves the archive. This is done automatically when platform=ios in applicationWillTerminate;, but must be done manually in platform=watchos, preferably in WKExtensionDelegate applicationWillResignActive.
- (void)waitUntilAllLogsAreConsumedAndArchiveSaved;

@end
