//
//  ARKLogTableViewController.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKLogFormatter;


@interface ARKLogTableViewController : UITableViewController

/// The formatter used to prepare the logs for the share/activity sheet.
@property (nonatomic, copy, readwrite) id <ARKLogFormatter> logFormatter;

@end
