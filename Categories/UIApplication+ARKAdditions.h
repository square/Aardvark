//
//  UIApplication+ARKAdditions.h
//  Aardvark
//
//  Created by Dan Federman on 10/10/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKBugReporter;


@interface UIApplication (ARKAdditions)

/// Adds a two finger press and hold gesture recognizer to the application. Triggering that gesture causes bugReporter to compose a bug report.
- (void)ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:(id <ARKBugReporter>)bugReporter;

/// Adds a gesture recognizer of class gestureRecognizerClass to the application. Triggering that gesture causes bugReporter to compose a bug report.
- (UIGestureRecognizer *)ARK_addBugReporter:(id <ARKBugReporter>)bugReporter withTriggeringGestureRecognizerOfClass:(Class)gestureRecognizerClass;

/// Removes bugReporter and the associated gestureRecognizer.
- (void)ARK_removeBugReporter:(id <ARKBugReporter>)bugReporter;

@end
