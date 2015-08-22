//
//  ARKLogTableViewController.h
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

#import <UIKit/UIKit.h>


@protocol ARKLogFormatter;
@class ARKLogStore;


NS_ASSUME_NONNULL_BEGIN


/// Displays a list of ARKArdvarkLogs in a table.
@interface ARKLogTableViewController : UITableViewController

/**
 Creates a log table view controller displaying logs from the default `ARKLogDistributor`'s default log store, using a default log formatter.
 */
- (instancetype)init;

/**
 @param logStore The log store from which to display logs. Must not be nil.
 @param logFormatter A log formatter used to format display of log messages. Must not be nil.
 */
- (nullable instancetype)initWithLogStore:(nonnull ARKLogStore *)logStore logFormatter:(nonnull id <ARKLogFormatter>)logFormatter NS_DESIGNATED_INITIALIZER;

/// The log store that provides the data for the table.
@property (nonatomic, readonly) ARKLogStore *logStore;

/// The formatter used to prepare the logs for the share/activity sheet.
@property (nonatomic, readonly) id <ARKLogFormatter> logFormatter;

/// The number of minutes between timestamps. Defaults to 3.
@property (nonatomic) NSUInteger minutesBetweenTimestamps;

/// Returns an array suitable for sharing via the activity sheet.
- (NSArray *)contentForActivitySheet;

@end


NS_ASSUME_NONNULL_END
