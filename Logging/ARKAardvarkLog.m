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
    if ([Aardvark isAardvarkLoggingEnabled]) {
        return [super allocWithZone:zone];
    } else {
        return nil;
    }
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
