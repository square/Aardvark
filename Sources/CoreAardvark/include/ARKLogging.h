//
//  Copyright 2016 Square, Inc.
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

#if SWIFT_PACKAGE
#import "ARKLogTypes.h"
#else
#import <CoreAardvark/ARKLogTypes.h>
#endif


/// Logs a log with default type to the default log distributor.
OBJC_EXTERN void ARKLog(NSString * _Nonnull format, ...) NS_FORMAT_FUNCTION(1,2);

/// Logs a log with customized type and userInfo to the default log distributor.
OBJC_EXTERN void ARKLogWithType(ARKLogType type, NSDictionary * _Nullable userInfo, NSString * _Nonnull format, ...) NS_FORMAT_FUNCTION(3,4);

/// Logs a log with parameters to the default log distributor.
OBJC_EXTERN void ARKLogWithParameters(NSDictionary<NSString *, NSString *> * _Nonnull parameters, NSString * _Nonnull format, ...) NS_FORMAT_FUNCTION(2, 3);

/// Logs a log with customized type and parameters to the default log distributor.
OBJC_EXTERN void ARKLogWithTypeAndParameters(ARKLogType type, NSDictionary<NSString *, NSString *> * _Nonnull parameters, NSString * _Nonnull format, ...) NS_FORMAT_FUNCTION(3, 4);
