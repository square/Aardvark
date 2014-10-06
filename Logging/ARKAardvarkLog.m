//
//  ARKAardvarkLog.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKAardvarkLog.h"


@implementation ARKAardvarkLog

#pragma mark - Class Methods

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone;
{
#if AARDVARK_LOG_ENABLED
    return [super allocWithZone:zone];
#else
    return nil;
#endif
}

+ (NSArray *)formattedLogs:(NSArray *)logs;
{
    return [self _formattedLogs:logs withImages:YES];
}

+ (NSString *)formattedLogsAsPlainText:(NSArray *)logs;
{
    return [[self _formattedLogs:logs withImages:NO] componentsJoinedByString:@"\n"];
}

+ (NSData *)formattedLogsAsData:(NSArray *)logs;
{
    return [[self formattedLogsAsPlainText:logs] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)mostRecentImageAsPNG:(NSArray *)logs;
{
    for (ARKAardvarkLog *log in [logs reverseObjectEnumerator]) {
        if (log.image != nil) {
            return UIImagePNGRepresentation(log.image);
        }
    }
    
    return nil;
}

+ (NSString *)recentErrorLogsAsPlainText:(NSArray *)logs count:(NSUInteger)errorLogsToInclude;
{
    NSMutableString *recentErrorLogs = [NSMutableString new];
    NSUInteger failuresFound = 0;
    for (ARKAardvarkLog *log in [logs reverseObjectEnumerator]) {
        if(log.type == ARKLogTypeError) {
            [recentErrorLogs appendFormat:@"%@\n", log];
            
            if(++failuresFound > errorLogsToInclude) {
                break;
            }
        }
    }
    
    return recentErrorLogs;
}

+ (NSArray *)_formattedLogs:(NSArray *)logs withImages:(BOOL)images;
{
    NSMutableArray *combinedLogs = [[NSMutableArray alloc] init];
    
    for (ARKAardvarkLog *log in logs) {
        switch (log.type) {
            case ARKLogTypeSeparator:
                [combinedLogs addObject:[NSString stringWithFormat:@"------------- %@ -------------\n", [log.text capitalizedString]]];
                break;
            case ARKLogTypeError:
                [combinedLogs addObject:@"!!!!!!!!!!!! FAILURE DETECTED !!!!!!!!!!!!\n"];
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

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    _text = [text copy];
    _image = image;
    _type = type;
    _createdAt = [NSDate date];
    
    return self;
}


#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    _text = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARKSelfKeyPath(text)];
    _image = [aDecoder decodeObjectOfClass:[UIImage class] forKey:ARKSelfKeyPath(image)];
    _type = (ARKLogType)[[aDecoder decodeObjectOfClass:[NSNumber class] forKey:ARKSelfKeyPath(type)] unsignedIntegerValue];
    _createdAt = [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARKSelfKeyPath(createdAt)];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeObject:self.text forKey:ARKSelfKeyPath(text)];
    [aCoder encodeObject:self.image forKey:ARKSelfKeyPath(image)];
    [aCoder encodeObject:@(self.type) forKey:ARKSelfKeyPath(type)];
    [aCoder encodeObject:self.createdAt forKey:ARKSelfKeyPath(createdAt)];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone;
{
    // We're immutable, so just return self.
    return self;
}

#pragma mark - NSObject

- (NSString *)description;
{
    NSString *dateString = [NSDateFormatter localizedStringFromDate:self.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    return [NSString stringWithFormat:@"[%@] %@", dateString, self.text];
}

@end
