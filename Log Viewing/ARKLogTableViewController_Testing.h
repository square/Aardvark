//
//  ARKLogTableViewController_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 12/15/14.
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

#import "ARKLogMessage.h"


@interface ARKLogTableViewController (Private)

@property (nonatomic, copy, readonly) NSArray *logMessages;

- (void)_reloadLogs;

@end


@interface ARKTimestampLogMessage : ARKLogMessage

- (instancetype)initWithDate:(NSDate *)date NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo NS_UNAVAILABLE;
- (instancetype)initWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo creationDate:(NSDate *)date NS_UNAVAILABLE;


@end
