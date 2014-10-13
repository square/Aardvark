//
//  Aardvark.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "Aardvark.h"

#import "ARKEmailBugReporter.h"
#import "ARKLogController.h"
#import "ARKLogMessage.h"
#import "UIApplication+ARKAdditions.h"


void ARKLog(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogController defaultController] appendLog:format arguments:argList];
    va_end(argList);
}

void ARKTypeLog(ARKLogType type, NSDictionary *userInfo, NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogController defaultController] appendLogType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

void ARKLogScreenshot()
{
    [[ARKLogController defaultController] appendLogScreenshot];
}


@implementation Aardvark

#pragma mark - Class Methods

+ (void)enableDefaultLogController;
{
    [ARKLogController defaultController].loggingEnabled = YES;
}

+ (void)disableDefaultLogController;
{
    [ARKLogController defaultController].loggingEnabled = NO;
}

+ (id <ARKBugReporter>)addDefaultBugReportingGestureWithBugReportRecipient:(NSString *)emailAddress;
{
    NSAssert([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:)], @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter emailBugReporterWithEmailAddress:emailAddress];
    [bugReporter addLogControllerLogMessagesToFutureBugReports:[ARKLogController defaultController]];
    
    [[UIApplication sharedApplication] ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:bugReporter];
    
    return bugReporter;
}

+ (id <ARKBugReporter>)addDefaultBugReportingGestureWithBugReportRecipient:(NSString *)emailAddress prefilledBugReportBody:(NSString *)prefilledBody;
{
    NSAssert([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:)], @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter emailBugReporterWithEmailAddress:emailAddress prefilledEmailBody:prefilledBody];
    [bugReporter addLogControllerLogMessagesToFutureBugReports:[ARKLogController defaultController]];
    
    [[UIApplication sharedApplication] ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:bugReporter];
    
    return bugReporter;
}

+ (UIGestureRecognizer *)addBugReporter:(id <ARKBugReporter>)bugReporter withTriggeringGestureRecognizerOfClass:(Class)gestureRecognizerClass;
{
    NSAssert([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addBugReporter:withTriggeringGestureRecognizerOfClass:)], @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    return [[UIApplication sharedApplication] ARK_addBugReporter:bugReporter withTriggeringGestureRecognizerOfClass:gestureRecognizerClass];
}

@end
