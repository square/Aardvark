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
#if AARDVARK_LOG_ENABLED
    if (format.length > 0) {
        va_list argList;
        va_start(argList, format);
        
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:[[NSString alloc] initWithFormat:format arguments:argList] image:nil type:ARKLogTypeDefault];
        [[ARKLogController sharedInstance] appendLog:log];
        
        va_end(argList);
    }
#endif
}

void ARKTypeLog(ARKLogType type, NSString *format, ...)
{
#if AARDVARK_LOG_ENABLED
    if (format.length > 0) {
        va_list argList;
        va_start(argList, format);
        
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:[[NSString alloc] initWithFormat:format arguments:argList] image:nil type:type];
        [[ARKLogController sharedInstance] appendLog:log];
        
        va_end(argList);
    }
#endif
}

void ARKLogScreenshot()
{
#if AARDVARK_LOG_ENABLED
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:@"📷📱 Screenshot!" image:screenshot type:ARKLogTypeDefault];
    [[ARKLogController sharedInstance] appendLog:log];
#endif
}


@implementation Aardvark

+ (void)setupBugReportingWithRecipientEmailAddress:(NSString *)recipientAddress;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = recipientAddress;
    
    [self setupBugReportingWithReporter:bugReporter];
}

+ (void)setupBugReportingWithReporter:(ARKEmailBugReporter *)bugReporter;
{
    [ARKLogController sharedInstance].bugReporter = bugReporter;
    [[ARKLogController sharedInstance] installScreenshotGestureRecognizer];

}

@end
