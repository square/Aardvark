//
//  ARKScreenshotViewController.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
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

#import <CoreAardvark/ARKLogMessage.h>

#import "ARKScreenshotViewController.h"

#import "UIActivityViewController+ARKAdditions.h"


@interface ARKScreenshotViewController ()

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, weak) UIActivityViewController *activityViewController;

@end


@implementation ARKScreenshotViewController

#pragma mark - Initialization

- (instancetype)initWithLogMessage:(ARKLogMessage *)logMessage;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _imageView = [[UIImageView alloc] initWithImage:logMessage.image];
    _date = logMessage.date;
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapDetected:)];
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.imageView.frame = self.view.bounds;
    self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.imageView];
    
    self.title = [NSDateFormatter localizedStringFromDate:self.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.imageView.window addGestureRecognizer:self.tapGestureRecognizer];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_openActivitySheet:)];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Private Methods

- (void)_tapDetected:(UITapGestureRecognizer *)tapRecognizer;
{
    if (tapRecognizer == self.tapGestureRecognizer && tapRecognizer.state == UIGestureRecognizerStateRecognized && !self.activityViewController) {
        CGPoint where = [tapRecognizer locationInView:self.imageView];
        
        // Make sure the user isn't tapping on the navigation bar.
        BOOL userTappedImage = NO;
        CGRect const navBarFrame = CGRectMake(0.0, 0.0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height + 20.0);
        userTappedImage = !CGRectContainsPoint(navBarFrame, where);
        
        if (userTappedImage) {
            [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
        }
    }
}

- (IBAction)_openActivitySheet:(id)sender;
{
    UIActivityViewController *activityViewController = [UIActivityViewController ARK_newAardvarkActivityViewControllerWithItems:@[self.imageView.image]];
    self.activityViewController = activityViewController;
    
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

@end
