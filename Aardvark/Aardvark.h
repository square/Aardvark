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
#import <Aardvark/ARKDefaultLogFormatter.h>
#import <Aardvark/ARKLogDistributor+UIAdditions.h>
#import <Aardvark/ARKEmailBugReporter.h>
#import <Aardvark/ARKIndividualLogViewController.h>
#import <Aardvark/ARKLogFormatter.h>
#import <Aardvark/ARKLogTableViewController.h>
#import <Aardvark/ARKScreenshotLogging.h>
#import <Aardvark/ARKScreenshotViewController.h>


//! Project version number for Aardvark-iOS.
FOUNDATION_EXPORT double Aardvark_iOSVersionNumber;

//! Project version string for Aardvark-iOS.
FOUNDATION_EXPORT const unsigned char Aardvark_iOSVersionString[];


@interface Aardvark : NSObject

/// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to emailAddress. Returns the created bug reporter for convenience.
+ (nullable ARKEmailBugReporter *)addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:(nonnull NSString *)emailAddress;

/// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
+ (nullable id)addBugReporter:(nonnull id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(nonnull Class)gestureRecognizerClass;

@end
