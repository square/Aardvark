//
//  ViewController.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@property (nonatomic, strong, readwrite) UITapGestureRecognizer *tapRecognizer;

@end


@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapDetected:)];
    [self.view addGestureRecognizer:self.tapRecognizer];
}

- (void)viewDidDisappear:(BOOL)animated;
{
    [self.tapRecognizer.view removeGestureRecognizer:self.tapRecognizer];
    
    [super viewDidAppear:animated];
}

#pragma mark - Private Methods

- (void)_tapDetected:(UITapGestureRecognizer *)tapRecognizer;
{
    if (tapRecognizer == self.tapRecognizer) {
        ARKLog(@"Tapped %@", NSStringFromCGPoint([tapRecognizer locationInView:self.view]));
    }
}

@end
