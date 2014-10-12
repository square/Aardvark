//
//  ARKLogTableViewController.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogController;
@protocol ARKLogFormatter;


/// Displays a list of ARKArdvarkLogs in a table.
@interface ARKLogTableViewController : UITableViewController

- (instancetype)initWithLogController:(ARKLogController *)logController logFormatter:(id <ARKLogFormatter>)logFormatter __attribute__((objc_designated_initializer));

/// The log controller that acts as the data source for the table.
@property (nonatomic, strong, readonly) ARKLogController *logController;

/// The formatter used to prepare the logs for the share/activity sheet.
@property (nonatomic, strong, readonly) id <ARKLogFormatter> logFormatter;

@end
