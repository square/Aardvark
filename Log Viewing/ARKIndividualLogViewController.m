//
//  ARKIndividualLogViewController.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKIndividualLogViewController.h"


@implementation ARKIndividualLogViewController

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.textView.text = self.text;
    self.textView.frame = self.view.bounds;
    self.textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.textView.editable = NO;
    [self.view addSubview:self.textView];
}

@end
