//
//  SampleViewController.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/11/14.
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

#import <Aardvark/Aardvark.h>
#import <CoreAardvark/CoreAardvark.h>

#import "SampleAppDelegate.h"
#import "SampleViewController.h"


NSString *const SampleViewControllerTapLogKey = @"SampleViewControllerTapLog";


@interface SampleViewController ()

@property (nonatomic) ARKLogStore *tapGestureLogStore;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@end


@implementation SampleViewController

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.tapGestureLogStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"SampleTapLogs.data"];
    self.tapGestureLogStore.name = @"Taps";
    
    // Ensure that the tap log store will only store tap logs.
    self.tapGestureLogStore.logFilterBlock = ^(ARKLogMessage *logMessage) {
        return [logMessage.userInfo[SampleViewControllerTapLogKey] boolValue];
    };
    
    // Do not log tap logs to the main tap log store.
    [ARKLogDistributor defaultDistributor].defaultLogStore.logFilterBlock = ^(ARKLogMessage *logMessage) {
        return (BOOL)![logMessage.userInfo[SampleViewControllerTapLogKey] boolValue];
    };
    
    [[ARKLogDistributor defaultDistributor] addLogObserver:self.tapGestureLogStore];
    
    ARKEmailBugReporter *bugReporter = ((SampleAppDelegate *)[UIApplication sharedApplication].delegate).bugReporter;
    [bugReporter addLogStores:@[self.tapGestureLogStore]];
}

- (void)viewDidAppear:(BOOL)animated;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapDetected:)];
    self.tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.tapRecognizer.view removeGestureRecognizer:self.tapRecognizer];
    self.tapRecognizer = nil;
    
    [super viewDidDisappear:animated];
}

#pragma mark - Actions

- (IBAction)viewARKLogMessages:(id)sender;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    ARKLogTableViewController *defaultLogsViewController = [ARKLogTableViewController new];
    [self.navigationController pushViewController:defaultLogsViewController animated:YES];
}

- (IBAction)viewTapLogs:(id)sender;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    ARKLogTableViewController *tapLogsViewController = [[ARKLogTableViewController alloc] initWithLogStore:self.tapGestureLogStore logFormatter:[ARKDefaultLogFormatter new]];
    [self.navigationController pushViewController:tapLogsViewController animated:YES];
}

- (IBAction)blueButtonPressed:(id)sender;
{
    ARKLog(@"Blue");
}

- (IBAction)redButtonPressed:(id)sender;
{
    ARKLog(@"Red");
}

- (IBAction)greenButtonPressed:(id)sender;
{
    ARKLog(@"Green");
}

- (IBAction)yellowButtonPressed:(id)sender;
{
    ARKLog(@"Yellow");
}

#pragma mark - Private Methods

- (void)_tapDetected:(UITapGestureRecognizer *)tapRecognizer;
{
    if (tapRecognizer == self.tapRecognizer && tapRecognizer.state == UIGestureRecognizerStateEnded) {
        ARKLogWithType(ARKLogTypeDefault, @{ SampleViewControllerTapLogKey : @YES }, @"Tapped %@", NSStringFromCGPoint([tapRecognizer locationInView:nil]));
    }
}

@end
