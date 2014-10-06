//
//  ARKLogFormatter.m
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKDefaultLogFormatter.h"

#import "ARKAardvarkLog.h"


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

- (NSArray *)formattedLogs:(NSArray *)logs;
{
    return [self _formattedLogs:logs withImages:YES];
}

- (NSString *)formattedLogsAsPlainText:(NSArray *)logs;
{
    return [[self _formattedLogs:logs withImages:NO] componentsJoinedByString:@"\n"];
}

- (NSData *)formattedLogsAsData:(NSArray *)logs;
{
    return [[self formattedLogsAsPlainText:logs] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)mostRecentImageAsPNG:(NSArray *)logs;
{
    for (ARKAardvarkLog *log in [logs reverseObjectEnumerator]) {
        if (log.image != nil) {
            return UIImagePNGRepresentation(log.image);
        }
    }
    
    return nil;
}

- (NSString *)recentErrorLogsAsPlainText:(NSArray *)logs count:(NSUInteger)errorLogsToInclude;
{
    NSMutableString *recentErrorLogs = [NSMutableString new];
    NSUInteger failuresFound = 0;
    for (ARKAardvarkLog *log in [logs reverseObjectEnumerator]) {
        if(log.type == ARKLogTypeError) {
            [recentErrorLogs appendFormat:@"%@\n", log];
            
            if(++failuresFound >= errorLogsToInclude) {
                break;
            }
        }
    }
    
    // Remove the final newline and create an immutable string.
    return [recentErrorLogs stringByReplacingCharactersInRange:NSMakeRange(recentErrorLogs.length - 1, 1) withString:@""];
}

- (NSArray *)_formattedLogs:(NSArray *)logs withImages:(BOOL)images;
{
    NSMutableArray *combinedLogs = [[NSMutableArray alloc] init];
    
    for (ARKAardvarkLog *log in logs) {
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
