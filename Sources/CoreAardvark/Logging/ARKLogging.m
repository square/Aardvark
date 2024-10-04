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
#import "ARKLogging.h"
#else
#import <CoreAardvark/ARKLogging.h>
#endif

#import "ARKLogDistributor.h"


void ARKLog(NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithFormat:format arguments:argList];
    va_end(argList);
}

void ARKLogWithType(ARKLogType type, NSDictionary *userInfo, NSString *format, ...)
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

void ARKLogWithParameters(NSDictionary<NSString *, NSString *> *parameters, NSString *format, ...) {
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithParameters:parameters format:format arguments:argList];
    va_end(argList);
}

void ARKLogWithTypeAndParameters(ARKLogType type, NSDictionary<NSString *, NSString *> *parameters, NSString *format, ...) {
    va_list argList;
    va_start(argList, format);
    [[ARKLogDistributor defaultDistributor] logWithType:type parameters:parameters format:format arguments:argList];
    va_end(argList);
}
