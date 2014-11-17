//
//  ARKLogDistributor.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKLogConsumer;
@class ARKLogMessage;
@class ARKLogStore;


/// Distrubutes log messages to log consumers. All methods and properties on this class are threadsafe.
@interface ARKLogDistributor : NSObject

/// Returns the instance of the log distributor used by ARKLog().
+ (instancetype)defaultDistributor;

/// Defaults to ARKLogMessage. Can be set to a subclass of ARKLogMessage. Accessor blocks on log distributing queue; setter is non-blocking.
@property (nonatomic, assign, readwrite) Class logMessageClass;

/// Convenience method to store a reference to the default log store.
@property (nonatomic, strong, readwrite) ARKLogStore *defaultLogStore;

/// Retains an object that handles logging. Log handlers are sent consumeLogMessage: every time a log is appended. Allows for easy logging to third party services (i.e. Crashlytics, Mixpanel, etc). Non-blocking call.
- (void)addLogConsumer:(id <ARKLogConsumer>)logConsumer;

/// Releases an object that handles logging. Non-blocking call.
- (void)removeLogConsumer:(id <ARKLogConsumer>)logConsumer;

/// Distributes the log to the log consumers. Non-blocking call.
- (void)logMessage:(ARKLogMessage *)logMessage;

/// Creates a log message and distributes the log to the log consumers. Non-blocking call.
- (void)logWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;

/// Creates a log message and distributes the log to the log consumers. Non-blocking call.
- (void)logWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format arguments:(va_list)argList;

/// Creates a log message and distributes the log to the log consumers. Non-blocking call.
- (void)logWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);

/// Creates a log message with ARKLogTypeDefault and distributes the log to the log consumers. Non-blocking call.
- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;

/// Creates a log message with ARKLogTypeDefault and distributes the log to the log consumers. Non-blocking call.
- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/// Creates a log message with a screenshot and distributes the log to the log consumers. Non-blocking call.
- (void)logScreenshot;

@end
