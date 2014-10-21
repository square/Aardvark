//
//  ARKIndividualLogViewController.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogMessage;


@interface ARKIndividualLogViewController : UIViewController

- (instancetype)initWithLogMessage:(ARKLogMessage *)logMessage;

@end
