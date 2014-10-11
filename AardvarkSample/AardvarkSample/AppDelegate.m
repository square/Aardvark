//
//  AppDelegate.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "SampleLogger.h"


@implementation AppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    [Aardvark enableDefaultLogController];
    [Aardvark addDefaultBugReportingGestureWithBugReportRecipient:@"fake-email@aardvarkbugreporting.src"];
    [self _setupAdvancedLoggingOptions];
    
    ARKTypeLog(ARKLogTypeSeparator, @"Hello World");
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
    ARKTypeLog(ARKLogTypeError, @"Exiting Sample App");
}

#pragma mark - Private Methods

- (void)_setupAdvancedLoggingOptions;
{
    ARKLogController *defaultLogController = [ARKLogController defaultController];
    [defaultLogController addLogger:[[SampleLogger alloc] initWithLogController:[ARKLogController defaultController]]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    defaultLogController.persistedLogsFilePath = [applicationSupportDirectory stringByAppendingPathComponent:@"SampleAardvarkLogs.data"];
}

@end
