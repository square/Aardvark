//
//  Aardvark.h
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

#import <Aardvark/ARKBugReporter.h>
#import <Aardvark/ARKEmailBugReporter.h>


NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, ARKLogType) {
    /// Default log type.
    ARKLogTypeDefault,
    /// Marks the beginning or end of a task.
    ARKLogTypeSeparator,
    /// Marks that the log represents an error.
    ARKLogTypeError,
    /// Marks a log that has a screenshot attached.
    ARKLogTypeScreenshot,
};


/// Logs a log with default type to the default log distributor.
OBJC_EXTERN void ARKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

/// Logs a log with customized type and userInfo to the default log distributor.
OBJC_EXTERN void ARKLogWithType(ARKLogType type, NSDictionary * __nullable userInfo, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);

/// Logs a screenshot to the default log distributor.
OBJC_EXTERN void ARKLogScreenshot();


@interface Aardvark : NSObject

/// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to emailAddress. Returns the created bug reporter for convenience.
+ (nullable ARKEmailBugReporter *)addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:(NSString *)emailAddress;

/// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
+ (nullable id)addBugReporter:(id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(Class)gestureRecognizerClass;

@end


NS_ASSUME_NONNULL_END
