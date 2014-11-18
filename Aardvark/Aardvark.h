//
//  Aardvark.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, ARKLogType) {
    /// Default log type.
    ARKLogTypeDefault,
    /// Marks the beginning or end of a task.
    ARKLogTypeSeparator,
    /// Marks that the log represents an error.
    ARKLogTypeError,
};


@protocol ARKBugReporter;
@class ARKEmailBugReporter;
@class ARKLogDistributor;


/// Appends a log with type default to the default log distributor.
OBJC_EXTERN void ARKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

/// Logs a log with customized type and userInfo to the default log distributor.
OBJC_EXTERN void ARKTypeLog(ARKLogType type, NSDictionary *userInfo, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);

/// Logs a screenshot to the default log distributor.
OBJC_EXTERN void ARKLogScreenshot();


@interface Aardvark : NSObject

/// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to emailAddress. Returns the created bug reporter for convenience.
+ (ARKEmailBugReporter *)addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:(NSString *)emailAddress;

/// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport] after taking a screenshot.
+ (id)addBugReporter:(id <ARKBugReporter>)bugReporter withTriggeringGestureRecognizerOfClass:(Class)gestureRecognizerClass;

@end
