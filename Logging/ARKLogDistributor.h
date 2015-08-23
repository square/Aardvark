//
//  ARKLogDistributor.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
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

#import <Aardvark/Aardvark.h>


@protocol ARKLogObserver;
@class ARKLogMessage;
@class ARKLogStore;


NS_ASSUME_NONNULL_BEGIN


/// Distrubutes log messages to log observers. All methods and properties on this class are threadsafe.
@interface ARKLogDistributor : NSObject

/// Returns the instance of the log distributor used by ARKLog().
+ (nullable instancetype)defaultDistributor;

/// Defaults to ARKLogMessage. Can be set to a subclass of ARKLogMessage.
@property Class logMessageClass;

/// Convenience method to store a reference to the default log store. Lazily creates a log store when accessed for the first time if one is not already set.
@property ARKLogStore *defaultLogStore;

/// Returns all instances of `ARKLogStore` that are currently registered as observers on this log distributor.
@property (atomic, copy, readonly) NSSet *logStores;

/// Retains an object that handles logging. Log observers are sent observeLogMessage: every time a log is appended. Allows for easy logging to third party services (i.e. Crashlytics, Mixpanel, etc).
- (void)addLogObserver:(id <ARKLogObserver>)logObserver;

/// Releases an object that handles logging.
- (void)removeLogObserver:(id <ARKLogObserver>)logObserver;

/// Distributes all enqueued log messages to log observers prior to calling the completionHandler. Completion handler is called on the main queue.
- (void)distributeAllPendingLogsWithCompletionHandler:(dispatch_block_t)completionHandler;

/// Distributes the log to the log observers.
- (void)logMessage:(ARKLogMessage *)logMessage;

/// Creates a log message and distributes the log to the log observers.
- (void)logWithText:(NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo;

/// Creates a log message and distributes the log to the log observers.
- (void)logWithType:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo format:(NSString *)format arguments:(va_list)argList;

/// Creates a log message and distributes the log to the log observers.
- (void)logWithType:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

/// Creates a log message with ARKLogTypeDefault and distributes the log to the log observers.
- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;

/// Creates a log message with ARKLogTypeDefault and distributes the log to the log observers.
- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/// Creates a log message with a screenshot and distributes the log to the log observers.
- (void)logScreenshot;

@end


NS_ASSUME_NONNULL_END
