//
//  ARKLogTableViewController.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKLogFormatter;
@class ARKLogStore;


/// Displays a list of ARKArdvarkLogs in a table.
@interface ARKLogTableViewController : UITableViewController

- (instancetype)initWithLogStore:(ARKLogStore *)logStore logFormatter:(id <ARKLogFormatter>)logFormatter;

/// The log store that provides the data for the table.
@property (nonatomic, strong, readonly) ARKLogStore *logStore;

/// The formatter used to prepare the logs for the share/activity sheet.
@property (nonatomic, strong, readonly) id <ARKLogFormatter> logFormatter;

/// The number of minutes between timestamps. Defaults to 3.
@property (nonatomic, assign, readwrite) NSUInteger minutesBetweenTimestamps;

/// Returns an array suitable for sharing via the activity sheet.
- (NSArray *)contentForActivitySheet;

@end
