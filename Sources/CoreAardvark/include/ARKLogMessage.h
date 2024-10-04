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

@import UIKit;

#if SWIFT_PACKAGE
#import "ARKLogTypes.h"
#else
#import <CoreAardvark/ARKLogTypes.h>
#endif


@interface ARKLogMessage : NSObject <NSCopying, NSSecureCoding>

/// Creates an ARKLogMessage with the provided parameters, created at the current date.
/// @see initWithText:image:type:parameters:userInfo:date:
- (nonnull instancetype)initWithText:(nonnull NSString *)text
                               image:(nullable UIImage *)image
                                type:(ARKLogType)type
                          parameters:(nonnull NSDictionary<NSString *, NSString *> *)parameters
                            userInfo:(nullable NSDictionary *)userInfo;

- (nonnull instancetype)initWithText:(nonnull NSString *)text
                               image:(nullable UIImage *)image
                                type:(ARKLogType)type
                          parameters:(nonnull NSDictionary<NSString *, NSString *> *)parameters
                            userInfo:(nullable NSDictionary *)userInfo
                                date:(nonnull NSDate *)date NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

/// The date at which the message was logged.
@property (nonnull, nonatomic, copy, readonly) NSDate *date;

/// The text of the log message.
@property (nonnull, nonatomic, copy, readonly) NSString *text;

/// An optional image associated with the log message. Typically used for logs of type `ARKLogTypeScreenshot`.
@property (nullable, nonatomic, readonly) UIImage *image;

/// The type of the log message.
@property (nonatomic, readonly) ARKLogType type;

/// Details about the log message. This data is persisted.
@property (nonnull, nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *parameters;

/// Arbitrary information that can be used by ARKLogObserver objects. This data is not persisted.
@property (nonnull, nonatomic, copy, readonly) NSDictionary *userInfo;

@end
