//
//  Aardvark.h
//  Aardvark
//
//  Created by Evan Kimia on 10/22/15.
//  Copyright © 2015 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>


//! Project version number for Aardvark.
FOUNDATION_EXPORT double AardvarkVersionNumber;

//! Project version string for Aardvark.
FOUNDATION_EXPORT const unsigned char AardvarkVersionString[];


#import <Aardvark/ARKLogStore.h>
#import <Aardvark/ARKEmailBugReporter.h>
#import <Aardvark/ARKLogMessage.h>
#import <Aardvark/ARKLogDistributor.h>
#import <Aardvark/ARKDefaultLogFormatter.h>
#import <Aardvark/ARKIndividualLogViewController.h>
#import <Aardvark/ARKLogObserver.h>
#import <Aardvark/ARKLogFormatter.h>
#import <Aardvark/UIApplication+ARKAdditions.h>
#import <Aardvark/ARKScreenshotViewController.h>
#import <Aardvark/ARKLogTableViewController.h>
#import <Aardvark/ARKBugReporter.h>
#import <Aardvark/ARKLogType.h>

NS_ASSUME_NONNULL_BEGIN


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
