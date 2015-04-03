//
//  SampleAppDelegate.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright 2014 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SampleAppDelegate.h"

#import "SampleCrashlyticsLogObserver.h"


@implementation SampleAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    // This line is all you'll need to get started.
    self.bugReporter = [Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:@"fake-email@aardvarkbugreporting.src"];
    
    // Log all ARKLog messages to Crashlytics to help debug crashes.
    [[ARKLogDistributor defaultDistributor] addLogObserver:[SampleCrashlyticsLogObserver new]];
    
    ARKLogWithType(ARKLogTypeSeparator, nil, @"Hello World");
    
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
    ARKLogWithType(ARKLogTypeError, nil, @"Exiting Sample App");
}

@end
