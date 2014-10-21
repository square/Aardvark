//
//  ARKLogFormatter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@protocol ARKLogFormatter <NSObject>

@required

/// Returns an array of NSStrings and UIImages that represent the logs.
- (NSArray *)formattedLogMessagesWithImages:(NSArray *)logMessages;

/// Returns formattedLogMessages as plain text, stripping out images.
- (NSString *)formattedLogMessagesAsPlainText:(NSArray *)logMessages;

/// Returns formattedLogMessagesAsPlainText as NSData.
- (NSData *)formattedLogMessagesAsData:(NSArray *)logMessages;

/// Returns the most recent image in a log as a PNG.
- (NSData *)mostRecentImageAsPNG:(NSArray *)logMessages;

/// Returns errorLogsToInclude recent error logs as a NSString.
- (NSString *)recentErrorLogMessagesAsPlainText:(NSArray *)logMessages count:(NSUInteger)errorLogsToInclude;

@end
