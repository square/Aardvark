//
//  ARKIndividualLogViewController.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKIndividualLogViewController : UIViewController

@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic, copy, readwrite) NSString *text;

@end
