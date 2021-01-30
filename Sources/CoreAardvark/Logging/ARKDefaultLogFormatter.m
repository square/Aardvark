//
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

#import "ARKDefaultLogFormatter.h"
#import "ARKLogTypes.h"
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
        case ARKLogTypeScreenshot:
        case ARKLogTypeDefault:
            // Do nothing special.
            break;
    }
    
    if (prefixPrepended && (logMessage.text.length > 0 || [logMessage.parameters count] > 0)) {
        [formattedLogMessage appendString:@"\n"];
    }
    
    [formattedLogMessage appendFormat:@"%@", logMessage];
    
    return [formattedLogMessage copy];
}

@end
