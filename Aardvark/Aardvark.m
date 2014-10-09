//
//  Aardvark.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "Aardvark.h"

#import "ARKAardvarkLog.h"
#import "ARKEmailBugReporter.h"
#import "ARKLogController.h"


void ARKLog(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogController sharedInstance] appendLog:format arguments:argList];
    va_end(argList);
}

void ARKTypeLog(ARKLogType type, NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogController sharedInstance] appendLogType:type format:format arguments:argList];
    va_end(argList);
}

void ARKLogScreenshot()
{
    [[ARKLogController sharedInstance] appendLogScreenshot];
}


@implementation Aardvark

#pragma mark - Class Methods

static NSNumber *AardvarkLoggingEnabled = NULL;

+ (void)enableAardvarkLogging;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AardvarkLoggingEnabled = @YES;
    });
}

+ (BOOL)isAardvarkLoggingEnabled;
{
    return [AardvarkLoggingEnabled boolValue];
}

+ (void)enableBugReportingWithEmailAddress:(NSString *)emailAddress;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = emailAddress;
    
    [self enableBugReportingWithReporter:bugReporter];
}

+ (void)enableBugReportingWithEmailAddress:(NSString *)emailAddress prefilledEmailBody:(NSString *)prefilledEmailBody;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = emailAddress;
    bugReporter.prefilledEmailBody = prefilledEmailBody;
    
    [self enableBugReportingWithReporter:bugReporter];
}

+ (void)enableBugReportingWithReporter:(id <ARKBugReporter>)bugReporter;
{
    if ([Aardvark isAardvarkLoggingEnabled]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            static id <ARKBugReporter> currentBugReporter = NULL;
            
            // Clean up the old bug reporter if it exists.
            if (currentBugReporter != NULL) {
                [currentBugReporter disableBugReporting];
            }
            
            // Hold onto the bug reporter.
            currentBugReporter = bugReporter;
            
            [bugReporter enableBugReporting];
        }];
    }
}

@end
