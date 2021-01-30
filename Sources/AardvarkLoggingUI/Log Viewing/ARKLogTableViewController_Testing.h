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


@interface ARKLogTableViewController (Private)

@property (nonnull, nonatomic, copy, readonly) NSArray *logMessages;

- (void)_reloadLogs;

@end


@interface ARKTimestampLogMessage : ARKLogMessage

- (nonnull instancetype)initWithDate:(nonnull NSDate *)date NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)initWithText:(nonnull NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type parameters:(nonnull NSDictionary<NSString *, NSString*> *)parameters userInfo:(nullable NSDictionary *)userInfo NS_UNAVAILABLE;
- (nonnull instancetype)initWithText:(nonnull NSString *)text image:(nullable UIImage *)image type:(ARKLogType)type parameters:(nonnull NSDictionary<NSString *, NSString*> *)parameters userInfo:(nullable NSDictionary *)userInfo date:(nonnull NSDate *)date NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

@end
