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

#import "SampleAppDelegate.h"
#import "SampleTapLogger.h"
#import "SampleViewController.h"


@interface SampleViewController ()

@property (nonatomic, readwrite, strong) ARKLogController *tapLogController;
@property (nonatomic, readwrite, strong) SampleTapLogger *tapLogger;

@end


@implementation SampleViewController

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.tapLogController = [ARKLogController new];
    self.tapLogController.loggingEnabled = YES;
    self.tapLogController.name = @"Taps";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    self.tapLogController.persistedLogsFilePath = [applicationSupportDirectory stringByAppendingPathComponent:@"SampleTapLogs.data"];
    
    self.tapLogger = [[SampleTapLogger alloc] initWithView:self.view logController:self.tapLogController];
    
    [((SampleAppDelegate *)[UIApplication sharedApplication].delegate).bugReporter addLogController:self.tapLogController];
}

- (void)viewDidAppear:(BOOL)animated;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.tapLogController addLogger:self.tapLogger];
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated;
{
    ARKLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.tapLogController removeLogger:self.tapLogger];
    
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
    ARKLogTableViewController *tapLogsViewController = [[ARKLogTableViewController alloc] initWithLogController:self.tapLogController logFormatter:[ARKDefaultLogFormatter new]];
    [self.navigationController pushViewController:tapLogsViewController animated:YES];
}

@end
