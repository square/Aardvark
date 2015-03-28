//
//  ARKLogMessage.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogMessage.h"


@implementation ARKLogMessage

#pragma mark - Class Methods

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    _text = [text copy];
    _image = image;
    _type = type;
    _userInfo = [userInfo copy];
    _creationDate = [NSDate date];
    
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
    _creationDate = [[aDecoder decodeObjectOfClass:[NSDate class] forKey:ARKSelfKeyPath(creationDate)] copy];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeObject:self.text forKey:ARKSelfKeyPath(text)];
    [aCoder encodeObject:self.image forKey:ARKSelfKeyPath(image)];
    [aCoder encodeObject:@(self.type) forKey:ARKSelfKeyPath(type)];
    [aCoder encodeObject:self.creationDate forKey:ARKSelfKeyPath(creationDate)];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone;
{
    // We're immutable, so just return self.
    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object;
{
    if (![self isMemberOfClass:[object class]]) {
        return NO;
    }
    
    ARKLogMessage *otherMessage = (ARKLogMessage *)object;
    if (!(self.text == otherMessage.text || [self.text isEqualToString:otherMessage.text])) {
        return NO;
    }
    
    if (!(self.image == otherMessage.image || [self.image isEqual:otherMessage.image])) {
        return NO;
    }
    
    if (self.type != otherMessage.type) {
        return NO;
    }

    if (![self.creationDate isEqualToDate:otherMessage.creationDate]) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash;
{
    return self.creationDate.hash;
}

- (NSString *)description;
{
    NSString *dateString = [NSDateFormatter localizedStringFromDate:self.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    return [NSString stringWithFormat:@"[%@] %@", dateString, self.text];
}

@end
