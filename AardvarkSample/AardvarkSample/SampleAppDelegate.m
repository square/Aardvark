//
//  SampleAppDelegate.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "SampleAppDelegate.h"

#import "SampleCrashlyticsLogConsumer.h"


@implementation SampleAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    // This line is all you'll need to get started.
    self.bugReporter = [Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:@"fake-email@aardvarkbugreporting.src"];
    
    // Log all ARKLog messages to Crashlytics to help debug crashes.
    [[ARKLogDistributor defaultDistributor] addLogConsumer:[SampleCrashlyticsLogConsumer new]];
    
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
