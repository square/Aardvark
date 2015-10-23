//
//  UIApplication+ARKAdditions.m
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

#import <objc/runtime.h>

#import "UIApplication+ARKAdditions.h"

#import "AardvarkDefines.h"
#import "ARKBugReporter.h"
#import "ARKLogDistributor.h"

@interface UIApplication (ARKAdditions_Private)

@property (nonatomic) NSMapTable *ARK_bugReporterToGestureRecognizerMap;
@property (nonatomic, getter=ARK_isObservingKeyWindowNotifications, setter=setARK_ObservingKeyWindowNotifications:) BOOL ARK_observingKeyWindowNotifications;

@end


@implementation UIApplication (ARKAdditions)

#pragma mark - Public Methods

- (void)ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:(id <ARKBugReporter>)bugReporter;
{
    UILongPressGestureRecognizer *bugReportingGestureRecognizer = (UILongPressGestureRecognizer *)[self ARK_addBugReporter:bugReporter triggeringGestureRecognizerClass:[UILongPressGestureRecognizer class]];
    bugReportingGestureRecognizer.numberOfTouchesRequired = 2;
}

- (id)ARK_addBugReporter:(id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(Class)gestureRecognizerClass;
{
    ARKCheckCondition(bugReporter.logStores.count > 0, nil, @"Attempting to add a bug reporter without a log store!");
    
    UIGestureRecognizer *bugReportingGestureRecognizer = [self _ARK_newBugReportingGestureRecognizerWithClass:gestureRecognizerClass];
    [self.keyWindow addGestureRecognizer:bugReportingGestureRecognizer];
    
    [self.ARK_bugReporterToGestureRecognizerMap setObject:bugReportingGestureRecognizer forKey:bugReporter];
    
    if (![self ARK_isObservingKeyWindowNotifications]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_ARK_windowDidBecomeKeyNotification:) name:UIWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_ARK_windowDidResignKeyNotification:) name:UIWindowDidResignKeyNotification object:nil];
        self.ARK_observingKeyWindowNotifications = YES;
    }
    
    return bugReportingGestureRecognizer;
}

- (void)ARK_removeBugReporter:(id <ARKBugReporter>)bugReporter;
{
    UIGestureRecognizer *gestureRecognizerToRemove = [self.ARK_bugReporterToGestureRecognizerMap objectForKey:bugReporter];
    [gestureRecognizerToRemove.view removeGestureRecognizer:gestureRecognizerToRemove];
    
    [self.ARK_bugReporterToGestureRecognizerMap removeObjectForKey:bugReporter];
}

#pragma mark - Private Methods

- (id)_ARK_newBugReportingGestureRecognizerWithClass:(Class)gestureRecognizerClass;
{
    ARKCheckCondition([gestureRecognizerClass isSubclassOfClass:[UIGestureRecognizer class]], nil, @"%@ is not a gesture recognizer class", NSStringFromClass(gestureRecognizerClass));
    
    UIGestureRecognizer *bugReportingGestureRecognizer = [[gestureRecognizerClass alloc] initWithTarget:self action:@selector(_ARK_didFireBugReportGestureRecognizer:)];
    bugReportingGestureRecognizer.cancelsTouchesInView = NO;
    
    return bugReportingGestureRecognizer;
}

- (void)_ARK_didFireBugReportGestureRecognizer:(UIGestureRecognizer *)bugReportRecognizer;
{
    if (bugReportRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSMutableSet *bugReporters = [NSMutableSet new];
    NSMapTable *bugReporterToGestureRecognizerMap = self.ARK_bugReporterToGestureRecognizerMap;
    for (id <ARKBugReporter> bugReporter in bugReporterToGestureRecognizerMap.keyEnumerator) {
        if ([bugReporterToGestureRecognizerMap objectForKey:bugReporter] == bugReportRecognizer) {
            [bugReporters addObject:bugReporter];
        }
    }
    
    if (bugReporters.count == 0) {
        return;
    }
    
    for (id <ARKBugReporter> bugReporter in bugReporters) {
        [bugReporter composeBugReport];
    }
}

- (void)_ARK_windowDidBecomeKeyNotification:(NSNotification *)notification;
{
    UIWindow *window = [[notification object] isKindOfClass:[UIWindow class]] ? (UIWindow *)[notification object] : nil;
    for (UIGestureRecognizer *gestureRecognizer in self.ARK_bugReporterToGestureRecognizerMap.objectEnumerator) {
        [window addGestureRecognizer:gestureRecognizer];
    }
}

- (void)_ARK_windowDidResignKeyNotification:(NSNotification *)notification;
{
    UIWindow *window = [[notification object] isKindOfClass:[UIWindow class]] ? (UIWindow *)[notification object] : nil;
    for (UIGestureRecognizer *gestureRecognizer in self.ARK_bugReporterToGestureRecognizerMap.objectEnumerator) {
        [window removeGestureRecognizer:gestureRecognizer];
    }
}

@end


@implementation UIApplication (ARKAdditions_Private)

@dynamic ARK_bugReporterToGestureRecognizerMap;
@dynamic ARK_observingKeyWindowNotifications;

#pragma mark - Properties

- (NSMapTable *)ARK_bugReporterToGestureRecognizerMap;
{
    NSMapTable *bugReporterToGestureRecognizerMap = objc_getAssociatedObject(self, @selector(ARK_bugReporterToGestureRecognizerMap));
    
    if (!bugReporterToGestureRecognizerMap) {
        bugReporterToGestureRecognizerMap = [NSMapTable strongToStrongObjectsMapTable];
        self.ARK_bugReporterToGestureRecognizerMap = bugReporterToGestureRecognizerMap;
    }
    
    return bugReporterToGestureRecognizerMap;
}

- (void)setARK_bugReporterToGestureRecognizerMap:(NSMapTable *)ARK_bugReporterToGestureRecognizerMap
{
    objc_setAssociatedObject(self, @selector(ARK_bugReporterToGestureRecognizerMap), ARK_bugReporterToGestureRecognizerMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)ARK_isObservingKeyWindowNotifications;
{
    return [objc_getAssociatedObject(self, @selector(ARK_isObservingKeyWindowNotifications)) boolValue];
}

- (void)setARK_ObservingKeyWindowNotifications:(BOOL)observingKeyWindowNotifications;
{
    objc_setAssociatedObject(self, @selector(ARK_isObservingKeyWindowNotifications), @(observingKeyWindowNotifications), OBJC_ASSOCIATION_ASSIGN);
}

@end
