//
//  ARKLogMessage.h
//  CoreAardvark
//
//  Created by Dan Federman on 10/4/14.
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

#if COCOAPODS
#import <Aardvark/ARKCoreLogging.h>
#else
#import <CoreAardvark/ARKCoreLogging.h>
#endif
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@interface ARKLogMessage : NSObject <NSCopying, NSSecureCoding>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// Creates an ARKLogMessage with the provided parameters, created at the current date.
/// @see initWithText:image:type:userInfo:creationDate:
- (instancetype)initWithText:(NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo;

- (instancetype)initWithText:(NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo creationDate:(NSDate *)date NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly) NSDate *creationDate;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly) ARKLogType type;

/// Arbitrary information used by ARKLogBlocks. This data is not persisted.
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;

@end


NS_ASSUME_NONNULL_END
