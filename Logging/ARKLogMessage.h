//
//  ARKLogMessage.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKLogMessage : NSObject <NSCopying, NSSecureCoding>

- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type flags:(NSUInteger)flags __attribute__((objc_designated_initializer));

@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) ARKLogType type;
@property (nonatomic, assign, readonly) NSUInteger flags;

@end
