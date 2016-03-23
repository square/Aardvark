//
//  ARKLogging.m
//  CoreAardvark
//
//  Created by Dan Federman on 7/25/16.
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

#import <CoreAardvark/ARKLogging.h>

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
