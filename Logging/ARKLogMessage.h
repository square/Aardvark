//
//  ARKLogMessage.h
//  Aardvark
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

#import <Aardvark/ARKLogging.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@interface ARKLogMessage : NSObject <NSCopying, NSSecureCoding>

- (instancetype)initWithText:(NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type userInfo:(nullable NSDictionary *)userInfo;

@property (nonatomic, copy, readonly) NSDate *creationDate;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) ARKLogType type;

/// Arbitrary information used by ARKLogBlocks. This data is not persisted
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

@end


NS_ASSUME_NONNULL_END
