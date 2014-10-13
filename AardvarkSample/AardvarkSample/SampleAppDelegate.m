//
//  SampleAppDelegate.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "SampleAppDelegate.h"

#import "SampleUIApplicationNotificationListenerLogger.h"


@implementation SampleAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    // These two lines are all you'll need to get started.
    [Aardvark enableDefaultLogController];
    self.bugReporter = [Aardvark addDefaultBugReportingGestureWithBugReportRecipient:@"fake-email@aardvarkbugreporting.src"];
    
    // Some examples of fancier logging.
    [self _setupUIApplicationEventLoggingOnDefaultController];
    
    ARKTypeLog(ARKLogTypeSeparator, 0, @"Hello World");
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
    ARKTypeLog(ARKLogTypeError, 0, @"Exiting Sample App");
}

#pragma mark - Private Methods

- (void)_setupUIApplicationEventLoggingOnDefaultController;
{
    [[ARKLogController defaultController] addLogger:[[SampleUIApplicationNotificationListenerLogger alloc] initWithLogController:[ARKLogController defaultController]]];
}

@end
