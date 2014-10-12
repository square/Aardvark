//
//  SampleLogger.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "SampleLogger.h"


@implementation SampleLogger

@synthesize logController = _logController;

#pragma mark - Initialization

- (instancetype)initWithLogController:(ARKLogController *)logController;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logController = logController;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)_applicationWillEnterForeground:(NSNotification *)notification;
{
    [self.logController appendLog:@"Application Will Enter Foreground"];
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification;
{
    [self.logController appendLog:@"Application Did Enter Background"];
}

@end
