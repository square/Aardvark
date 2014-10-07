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
    if ([Aardvark isAardvarkLoggingEnabled]) {
        if (format.length > 0) {
            va_list argList;
            va_start(argList, format);
            
            NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
            ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:ARKLogTypeDefault];
            [[ARKLogController sharedInstance] appendLog:log];
            
            if ([Aardvark isAardvarkLoggingToNSLog]) {
                NSLog(@"%@", logText);
            }
            
            va_end(argList);
        }
    }
}

void ARKTypeLog(ARKLogType type, NSString *format, ...)
{
    if ([Aardvark isAardvarkLoggingEnabled]) {
        if (format.length > 0) {
            va_list argList;
            va_start(argList, format);
            
            NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
            ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:type];
            [[ARKLogController sharedInstance] appendLog:log];
            
            if ([Aardvark isAardvarkLoggingToNSLog]) {
                NSLog(@"%@", logText);
            }
            
            va_end(argList);
        }
    }
}

void ARKLogScreenshot()
{
    if ([Aardvark isAardvarkLoggingEnabled]) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UIGraphicsBeginImageContext(window.bounds.size);
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSString *logText = @"📷📱 Screenshot!";
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:screenshot type:ARKLogTypeDefault];
        [[ARKLogController sharedInstance] appendLog:log];

        if ([Aardvark isAardvarkLoggingToNSLog]) {
            NSLog(@"%@", logText);
        }
    }
}


@implementation Aardvark

static NSNumber *AardvarkLoggingEnabled = NULL;
static NSNumber *AardvarkLoggingToNSLog = NULL;

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

+ (void)enableAardvarkLoggingToNSLog;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AardvarkLoggingToNSLog = @YES;
    });
}

+ (BOOL)isAardvarkLoggingToNSLog;
{
    return [AardvarkLoggingToNSLog boolValue];
}

+ (void)enableBugReportingWithEmailAddress:(NSString *)emailAddress;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = emailAddress;
    
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
