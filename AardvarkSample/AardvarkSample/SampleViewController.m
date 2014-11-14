//
//  SampleViewController.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/11/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKDefaultLogFormatter.h>
#import <Aardvark/ARKEmailBugReporter.h>
#import <Aardvark/ARKLogTableViewController.h>
#import <Aardvark/ARKLogStore.h>

#import "SampleAppDelegate.h"
#import "SampleViewController.h"


@interface SampleViewController ()

@property (nonatomic, readwrite, strong) ARKLogDistributor *tapLogDistributor;
@property (nonatomic, readwrite, strong) ARKLogStore *tapLogStore;
@property (nonatomic, strong, readwrite) UITapGestureRecognizer *tapRecognizer;

@end


@implementation SampleViewController

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.tapLogDistributor = [ARKLogDistributor new];
    
    self.tapLogStore = [ARKLogStore new];
    self.tapLogStore.name = @"Taps";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    self.tapLogStore.persistedLogsFileURL = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent:@"SampleTapLogs.data"]];
    
    [self.tapLogDistributor addLogConsumer:self.tapLogStore];
    
    ARKEmailBugReporter *bugReporter = ((SampleAppDelegate *)[UIApplication sharedApplication].delegate).bugReporter;
    [bugReporter addLogStores:@[self.tapLogStore]];
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
    ARKLogTableViewController *tapLogsViewController = [[ARKLogTableViewController alloc] initWithLogStore:self.tapLogStore logFormatter:[ARKDefaultLogFormatter new]];
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
        // Log directly to the tap log distributor rather than using ARKLog, which logs to the default log distributor.
        [self.tapLogDistributor appendLogWithFormat:@"Tapped %@", NSStringFromCGPoint([tapRecognizer locationInView:nil])];
    }
}

@end
