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
#if AARDVARK_LOGGING_ENABLED
    if (format.length > 0) {
        va_list argList;
        va_start(argList, format);
        
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:ARKLogTypeDefault];
        [[ARKLogController sharedInstance] appendLog:log];
        
#if AARDVARK_NSLOG_ENABLED
        NSLog(@"%@", logText);
#endif
        
        va_end(argList);
    }
#endif
}

void ARKTypeLog(ARKLogType type, NSString *format, ...)
{
#if AARDVARK_LOGGING_ENABLED
    if (format.length > 0) {
        va_list argList;
        va_start(argList, format);
        
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:type];
        [[ARKLogController sharedInstance] appendLog:log];
        
#if AARDVARK_NSLOG_ENABLED
        NSLog(@"%@", logText);
#endif
        
        va_end(argList);
    }
#endif
}

void ARKLogScreenshot()
{
#if AARDVARK_LOGGING_ENABLED
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSString *logText = @"📷📱 Screenshot!";
    ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:screenshot type:ARKLogTypeDefault];
    [[ARKLogController sharedInstance] appendLog:log];
    
#if AARDVARK_NSLOG_ENABLED
    NSLog(@"%@", logText);
#endif
    
#endif
}


@implementation Aardvark

+ (void)setupBugReportingWithRecipientEmailAddress:(NSString *)recipientAddress;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = recipientAddress;
    
    [self setupBugReportingWithReporter:bugReporter];
}

+ (void)setupBugReportingWithReporter:(id <ARKBugReporter>)bugReporter;
{
#if AARDVARK_LOGGING_ENABLED
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
#endif
}

@end
