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

@import CoreAardvark;

#import "ARKExceptionLogging.h"


NSUncaughtExceptionHandler *_Nullable ARKPreviousUncaughtExceptionHandler = nil;

void ARKHandleUncaughtException(NSException *exception)
{
    ARKLogWithType(ARKLogTypeError, nil, @"Uncaught exception '%@':\n%@", exception.name, exception.debugDescription);
    dispatch_semaphore_t logDistributionSemaphore = dispatch_semaphore_create(0);
    [[ARKLogDistributor defaultDistributor] distributeAllPendingLogsWithCompletionHandler:^{
        dispatch_semaphore_signal(logDistributionSemaphore);
    }];
    while (dispatch_semaphore_wait(logDistributionSemaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
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
