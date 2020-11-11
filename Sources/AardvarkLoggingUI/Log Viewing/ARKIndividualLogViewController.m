//
//  ARKIndividualLogViewController.m
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

@import CoreAardvark;

#import "ARKIndividualLogViewController.h"


@interface ARKIndividualLogViewController ()

@property (nonatomic, readonly) UITextView *textView;
@property (nonatomic, copy) NSString *text;

@end


@implementation ARKIndividualLogViewController

#pragma mark - Initialization

- (instancetype)initWithLogMessage:(ARKLogMessage *)logMessage;
{
    self = [super init];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _text = [NSString stringWithFormat:@"%@\n%@", logMessage.date, logMessage.text];
    
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
