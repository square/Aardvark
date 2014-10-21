//
//  ARKLogFormatter.m
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKDefaultLogFormatter.h"

#import "ARKLogMessage.h"


@implementation ARKDefaultLogFormatter

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _errorLogPrefix = @"!!!!!!!!!!!! FAILURE DETECTED !!!!!!!!!!!!";
    _separatorLogPrefix = @"-----------------------------------------";
    
    return self;
}

#pragma mark - ARKLogFormatter

- (NSArray *)formattedLogMessagesWithImages:(NSArray *)logMessages;
{
    return [self _formattedLogMessages:logMessages withImages:YES];
}

- (NSString *)formattedLogMessagesAsPlainText:(NSArray *)logMessages;
{
    return [[self _formattedLogMessages:logMessages withImages:NO] componentsJoinedByString:@""];
}

- (NSData *)formattedLogMessagesAsData:(NSArray *)logMessages;
{
    return [[self formattedLogMessagesAsPlainText:logMessages] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)mostRecentImageAsPNG:(NSArray *)logs;
{
    for (ARKLogMessage *log in [logs reverseObjectEnumerator]) {
        if (log.image != nil) {
            return UIImagePNGRepresentation(log.image);
        }
    }
    
    return nil;
}

- (NSString *)recentErrorLogMessagesAsPlainText:(NSArray *)logMessages count:(NSUInteger)errorLogsToInclude;
{
    NSMutableString *recentErrorLogs = [NSMutableString new];
    NSUInteger failuresFound = 0;
    for (ARKLogMessage *log in [logMessages reverseObjectEnumerator]) {
        if(log.type == ARKLogTypeError) {
            [recentErrorLogs appendFormat:@"%@\n", log];
            
            if(++failuresFound >= errorLogsToInclude) {
                break;
            }
        }
    }
    
    if (recentErrorLogs.length) {
        // Remove the final newline and create an immutable string.
        return [recentErrorLogs stringByReplacingCharactersInRange:NSMakeRange(recentErrorLogs.length - 1, 1) withString:@""];
    } else {
        return nil;
    }
}

- (NSArray *)_formattedLogMessages:(NSArray *)logMessages withImages:(BOOL)images;
{
    NSMutableArray *combinedLogs = [[NSMutableArray alloc] init];
    
    for (ARKLogMessage *log in logMessages) {
        switch (log.type) {
            case ARKLogTypeSeparator:
                [combinedLogs addObject:[NSString stringWithFormat:@"%@\n", self.separatorLogPrefix]];
                break;
            case ARKLogTypeError:
                [combinedLogs addObject:[NSString stringWithFormat:@"%@\n", self.errorLogPrefix]];
                break;
            default:
                break;
        }
        
        if (images && log.image != nil) {
            [combinedLogs addObject:log.image];
        } else {
            [combinedLogs addObject:[NSString stringWithFormat:@"%@\n", log]];
        }
    }
    
    return combinedLogs;
}

@end
