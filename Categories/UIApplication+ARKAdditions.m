//
//  UIApplication+ARKAdditions.m
//  Aardvark
//
//  Created by Dan Federman on 10/10/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "UIApplication+ARKAdditions.h"

#import "ARKBugReporter.h"
#import "ARKLogDistributor.h"


@interface UIApplication (ARKAdditions_Private)

@property (nonatomic, strong, readwrite) NSMapTable *ARK_bugReporterToGestureRecognizerMap;
@property (nonatomic, assign, readwrite, getter=ARK_isObservingKeyWindowNotifications, setter=setARK_ObservingKeyWindowNotifications:) BOOL ARK_observingKeyWindowNotifications;

@end


@implementation UIApplication (ARKAdditions)

#pragma mark - Public Methods

- (void)ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:(id <ARKBugReporter>)bugReporter;
{
    UILongPressGestureRecognizer *bugReportingGestureRecognizer = (UILongPressGestureRecognizer *)[self ARK_addBugReporter:bugReporter withTriggeringGestureRecognizerOfClass:[UILongPressGestureRecognizer class]];
    bugReportingGestureRecognizer.numberOfTouchesRequired = 2;
}

- (id)ARK_addBugReporter:(id <ARKBugReporter>)bugReporter withTriggeringGestureRecognizerOfClass:(Class)gestureRecognizerClass;
{
    NSAssert(bugReporter.logStores.count > 0, @"Attempting to add a bug reporter without a log store!");
    NSAssert([bugReporter conformsToProtocol:@protocol(ARKBugReporter)], @"Attempting to trigger bug reports with an object that does not conform to ARKBugReporter.");
    
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
    NSAssert([gestureRecognizerClass isSubclassOfClass:[UIGestureRecognizer class]], @"%@ is not a gesture recognizer class", NSStringFromClass(gestureRecognizerClass));
    
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
