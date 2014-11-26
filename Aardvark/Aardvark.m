//
//  Aardvark.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "Aardvark.h"

#import "ARKEmailBugReporter.h"
#import "ARKLogDistributor.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"
#import "UIApplication+ARKAdditions.h"


void ARKLog(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithFormat:format arguments:argList];
    va_end(argList);
}

void ARKLogWithType(ARKLogType type, NSDictionary *userInfo, NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

void ARKLogScreenshot()
{
    [[ARKLogDistributor defaultDistributor] logScreenshot];
}


@implementation Aardvark

#pragma mark - Class Methods

+ (ARKEmailBugReporter *)addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:(NSString *)emailAddress;
{
    ARKCheckCondition([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:)], nil, @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"ARKDefaultLogStore.data"];
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    
    ARKEmailBugReporter *bugReporter = [[ARKEmailBugReporter alloc] initWithEmailAddress:emailAddress logStore:logStore];
    
    [[UIApplication sharedApplication] ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:bugReporter];
    
    return bugReporter;
}

+ (id)addBugReporter:(id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(Class)gestureRecognizerClass;
{
    ARKCheckCondition([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addBugReporter:triggeringGestureRecognizerClass:)], nil, @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    return [[UIApplication sharedApplication] ARK_addBugReporter:bugReporter triggeringGestureRecognizerClass:gestureRecognizerClass];
}

@end
