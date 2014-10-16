//
//  SampleAppDelegate.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "SampleAppDelegate.h"


@implementation SampleAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    // These two lines are all you'll need to get started.
    [Aardvark enableDefaultLogController];
    self.bugReporter = [Aardvark addDefaultBugReportingGestureWithBugReportRecipient:@"fake-email@aardvarkbugreporting.src"];
    
    ARKTypeLog(ARKLogTypeSeparator, nil, @"Hello World");
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
    ARKLog(@"Application Will Enter Foreground");
}

- (void)applicationDidEnterBackground:(NSNotification *)notification;
{
    ARKLog(@"Application Did Enter Background");
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
    ARKTypeLog(ARKLogTypeError, nil, @"Exiting Sample App");
}

@end
