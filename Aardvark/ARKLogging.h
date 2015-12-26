//
//  ARKLogging.h
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

#import <Aardvark/ARKLogTypes.h>


/// Logs a log with default type to the default log distributor.
OBJC_EXTERN void ARKLog(NSString * __nonnull format, ...) NS_FORMAT_FUNCTION(1,2);

/// Logs a log with customized type and userInfo to the default log distributor.
OBJC_EXTERN void ARKLogWithType(ARKLogType type, NSDictionary * __nullable userInfo, NSString * __nonnull format, ...) NS_FORMAT_FUNCTION(3,4);

/// Logs a screenshot to the default log distributor.
OBJC_EXTERN void ARKLogScreenshot();
