//
//  ARKExceptionLogging.m
//  Aardvark
//
//  Created by Nick Entin on 9/7/17.
//  Copyright 2017 Square, Inc.
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

#import "ARKExceptionLogging.h"

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Protected.h"
#import "ARKLogging.h"


NSUncaughtExceptionHandler *_Nullable ARKPreviousUncaughtExceptionHandler = nil;

void ARKHandleUncaughtException(NSException *exception)
{
    ARKLogWithType(ARKLogTypeError, nil, @"Uncaught exception '%@':\n%@", exception.name, exception.debugDescription);
    [[ARKLogDistributor defaultDistributor] distributeAllPendingLogsWithCompletionHandler:^{}];
    [[ARKLogDistributor defaultDistributor] waitUntilAllPendingLogsHaveBeenDistributed];
    
    if (ARKPreviousUncaughtExceptionHandler != nil) {
        ARKPreviousUncaughtExceptionHandler(exception);
    }
}

void ARKEnableLogOnUncaughtException()
{
    ARKPreviousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&ARKHandleUncaughtException);
}

void ARKDisableLogOnUncaughtException()
{
    NSSetUncaughtExceptionHandler(ARKPreviousUncaughtExceptionHandler);
}
