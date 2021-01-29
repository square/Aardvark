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

#import <CoreAardvark/ARKLogMessage.h>

#import "AardvarkDefines.h"


@interface ARKLogMessage (Legacy)

// Used for decoding legacy messages only.
@property (nullable, nonatomic, copy, readonly) NSDate *creationDate __attribute__ ((deprecated));

@end


@implementation ARKLogMessage

#pragma mark - Class Methods

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;
{
    return [self initWithText:text image:image type:type userInfo:userInfo date:[NSDate date]];
}

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo date:(nonnull NSDate *)date;
{
    self = [super init];
    
    _text = [text copy];
    _image = image;
    _type = type;
    _userInfo = [userInfo copy] ?: @{};
    _date = date;
	
    return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    NSString *const text = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARKSelfKeyPath(text)];
    UIImage *const image = [aDecoder decodeObjectOfClass:[UIImage class] forKey:ARKSelfKeyPath(image)];
    ARKLogType const type = (ARKLogType)[[aDecoder decodeObjectOfClass:[NSNumber class] forKey:ARKSelfKeyPath(type)] unsignedIntegerValue];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    NSDate *const date = [([aDecoder decodeObjectOfClass:[NSDate class] forKey:ARKSelfKeyPath(date)] ?: [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARKSelfKeyPath(creationDate)]) copy];
#pragma clang diagnostic pop
    
    return [self initWithText:text image:image type:type userInfo:nil date:date];
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeObject:self.text forKey:ARKSelfKeyPath(text)];
    [aCoder encodeObject:self.image forKey:ARKSelfKeyPath(image)];
    [aCoder encodeObject:@(self.type) forKey:ARKSelfKeyPath(type)];
    [aCoder encodeObject:self.date forKey:ARKSelfKeyPath(date)];
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

    if (![self.date isEqualToDate:otherMessage.date]) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash;
{
    return self.date.hash;
}

- (NSString *)description;
{
    NSString *dateString = [NSDateFormatter localizedStringFromDate:self.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    return [NSString stringWithFormat:@"[%@] %@", dateString, self.text];
}

@end
