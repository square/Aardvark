//
//  ARKLogMessage.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKLogMessage : NSObject <NSCopying, NSSecureCoding>

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;

@property (nonatomic, copy, readonly) NSDate *creationDate;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) ARKLogType type;

/// Arbitrary information used by ARKLogBlocks. This data is not persisted
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

@end
