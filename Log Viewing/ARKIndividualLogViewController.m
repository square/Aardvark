//
//  ARKIndividualLogViewController.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKIndividualLogViewController.h"

#import "ARKLogMessage.h"


@interface ARKIndividualLogViewController ()

@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic, copy, readwrite) NSString *text;

@end


@implementation ARKIndividualLogViewController

#pragma mark - Initialization

- (instancetype)initWithLogMessage:(ARKLogMessage *)logMessage;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _text = [NSString stringWithFormat:@"%@\n%@", logMessage.creationDate, logMessage.text];
    
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
