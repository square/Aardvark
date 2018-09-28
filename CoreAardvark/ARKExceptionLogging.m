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

NSMutableArray *_Nullable ARKUncaughtExceptionLogDistributors = nil;

void ARKHandleUncaughtException(NSException *exception)
{
    for (ARKLogDistributor *logDistributor in ARKUncaughtExceptionLogDistributors) {
        [logDistributor logWithType:ARKLogTypeError userInfo:nil format:@"Uncaught exception '%@':\n%@", exception.name, exception.debugDescription];
        [logDistributor distributeAllPendingLogsWithCompletionHandler:^{}];
        [logDistributor waitUntilAllPendingLogsHaveBeenDistributed];
    }
    
    if (ARKPreviousUncaughtExceptionHandler != nil) {
        ARKPreviousUncaughtExceptionHandler(exception);
    }
}

void ARKEnableLogOnUncaughtException()
{
    ARKEnableLogOnUncaughtExceptionToLogDistributor([ARKLogDistributor defaultDistributor]);
}

void ARKEnableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor)
{
    if (ARKUncaughtExceptionLogDistributors == nil) {
        ARKUncaughtExceptionLogDistributors = [NSMutableArray arrayWithObject:logDistributor];

        ARKPreviousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&ARKHandleUncaughtException);

    } else {
        [ARKUncaughtExceptionLogDistributors addObject:logDistributor];
    }
}

void ARKDisableLogOnUncaughtException()
{
    ARKDisableLogOnUncaughtExceptionToLogDistributor([ARKLogDistributor defaultDistributor]);
}

void ARKDisableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor)
{
    [ARKUncaughtExceptionLogDistributors removeObject:logDistributor];

    // If that was the last log distributor, clean up the handler.
    if ([ARKUncaughtExceptionLogDistributors count] == 0) {
        NSSetUncaughtExceptionHandler(ARKPreviousUncaughtExceptionHandler);
        ARKPreviousUncaughtExceptionHandler = nil;
        ARKUncaughtExceptionLogDistributors = nil;
    }
}
