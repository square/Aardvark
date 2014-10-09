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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    [Aardvark enableAardvarkLogging];
    [Aardvark enableBugReportingWithEmailAddress:@"fake-email@aardvarkbugreporting.src"];
    [[ARKLogController sharedInstance] addLogger:[[SampleLogger alloc] initWithLogController:[ARKLogController sharedInstance]]];
    
    ARKTypeLog(ARKLogTypeSeparator, @"Hello World");
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application;
{
    ARKTypeLog(ARKLogTypeError, @"Exiting Sample App");
}

@end
