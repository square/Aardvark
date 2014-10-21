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

- (NSString *)formattedLogMessage:(ARKLogMessage *)logMessage;
{
    NSMutableString *formattedLogMessage = [NSMutableString new];
    
    BOOL prefixPrepended = NO;
    
    switch (logMessage.type) {
        case ARKLogTypeSeparator:
            [formattedLogMessage appendFormat:@"%@", self.separatorLogPrefix];
            prefixPrepended = YES;
            break;
        case ARKLogTypeError:
            [formattedLogMessage appendFormat:@"%@", self.errorLogPrefix];
            prefixPrepended = YES;
            break;
        default:
            break;
    }
    
    if (prefixPrepended && logMessage.text.length) {
        [formattedLogMessage appendString:@"\n"];
    }
    
    [formattedLogMessage appendFormat:@"%@", logMessage];
    
    return [formattedLogMessage copy];
}

@end
