//
//  UIApplication+ARKAdditions.h
//  Aardvark
//
//  Created by Dan Federman on 10/10/14.
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

#import <UIKit/UIKit.h>


@protocol ARKBugReporter;
@class ARKLogDistributor;


@interface UIApplication (ARKAdditions)

/// Adds a two finger press and hold gesture recognizer to the application. Triggering that gesture causes bugReporter to compose a bug report.
- (void)ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:(nonnull id <ARKBugReporter>)bugReporter;

/// Adds a gesture recognizer of class gestureRecognizerClass to the application and returns it. Triggering that gesture causes bugReporter to compose a bug report from bugReporter's logStores.
- (nullable id)ARK_addBugReporter:(nonnull id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(nonnull Class)gestureRecognizerClass;

/// Removes bugReporter and the associated gestureRecognizer.
- (void)ARK_removeBugReporter:(nonnull id <ARKBugReporter>)bugReporter;

@end
