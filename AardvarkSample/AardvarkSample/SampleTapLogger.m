//
//  SampleTapLogger.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/11/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "SampleTapLogger.h"


@interface SampleTapLogger ()

@property (nonatomic, strong, readwrite) UITapGestureRecognizer *tapRecognizer;

@end


@implementation SampleTapLogger

@synthesize logController = _logController;

#pragma mark - Initialization

- (instancetype)initWithView:(UIView *)view logController:(ARKLogController *)logController;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logController = logController;
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapDetected:)];
    [view addGestureRecognizer:_tapRecognizer];
    
    return self;
}

- (void)dealloc;
{
    [_tapRecognizer.view removeGestureRecognizer:_tapRecognizer];
}

#pragma mark - Private Methods

- (void)_tapDetected:(UITapGestureRecognizer *)tapRecognizer;
{
    if (tapRecognizer == self.tapRecognizer && tapRecognizer.state == UIGestureRecognizerStateEnded) {
        // Log directly to our controller. ARKLog logs to the default log controller, and we aren't guaranteed that our log controller is the default.
        [self.logController appendLog:@"Tapped %@", NSStringFromCGPoint([tapRecognizer locationInView:nil])];
    }
}

@end
