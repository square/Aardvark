//
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
#import "ARKExceptionLogging_Testing.h"

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Protected.h"
#import "ARKLogging.h"
#import "ARKLogObserver.h"


NSUncaughtExceptionHandler *_Nullable ARKPreviousUncaughtExceptionHandler = nil;

NSLock *_Nullable ARKUncaughtExceptionLogDistributorsLock = nil;

NSMutableArray *_Nullable ARKUncaughtExceptionLogDistributors = nil;

// Use aliases for getting/setting the uncaught exception handler so we can replace these in unit tests.
ARKUncaughtExceptionHandlerGetter ARKGetUncaughtExceptionHandler = NSGetUncaughtExceptionHandler;
ARKUncaughtExceptionHandlerSetter ARKSetUncaughtExceptionHandler = NSSetUncaughtExceptionHandler;

NSLock * ARKGetUncaughtExceptionLogDistributorsLock()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKUncaughtExceptionLogDistributorsLock = [NSLock new];
    });
    return ARKUncaughtExceptionLogDistributorsLock;
}

void ARKHandleUncaughtException(NSException *_Nonnull exception)
{
    NSLock *const logDistributorsLock = ARKGetUncaughtExceptionLogDistributorsLock();
    [logDistributorsLock lock];

    dispatch_group_t observerGroup = dispatch_group_create();

    for (ARKLogDistributor *const logDistributor in ARKUncaughtExceptionLogDistributors) {
        [logDistributor logWithType:ARKLogTypeError userInfo:nil format:@"Uncaught exception '%@':\n%@", exception.name, exception.debugDescription];
        [logDistributor distributeAllPendingLogsWithCompletionHandler:^{}];
        [logDistributor waitUntilAllPendingLogsHaveBeenDistributed];

        for (id<ARKLogObserver> observer in logDistributor.logObservers) {
            if ([observer respondsToSelector:@selector(processAllPendingLogsWithCompletionHandler:)]) {
                dispatch_group_enter(observerGroup);
                [observer processAllPendingLogsWithCompletionHandler:^{
                    dispatch_group_leave(observerGroup);
                }];
            }
        }
    }

    NSUncaughtExceptionHandler *const previousHandler = ARKPreviousUncaughtExceptionHandler;

    [logDistributorsLock unlock];

    // Wait for the logs to finish distributing before continuing, since otherwise the app will terminate and the
    // distribution (which normally happens in the background) won't complete.
    dispatch_group_wait(observerGroup, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));

    if (previousHandler != NULL) {
        previousHandler(exception);
    }
}

void ARKEnableLogOnUncaughtException()
{
    ARKEnableLogOnUncaughtExceptionToLogDistributor([ARKLogDistributor defaultDistributor]);
}

void ARKEnableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor)
{
    NSLock *const logDistributorsLock = ARKGetUncaughtExceptionLogDistributorsLock();
    [logDistributorsLock lock];
    
    // Set up the uncaught exception handler if this is the first distributor, otherwise just add it to the list.
    if (ARKUncaughtExceptionLogDistributors == nil) {
        ARKUncaughtExceptionLogDistributors = [NSMutableArray arrayWithObject:logDistributor];

        ARKPreviousUncaughtExceptionHandler = ARKGetUncaughtExceptionHandler();
        ARKSetUncaughtExceptionHandler(&ARKHandleUncaughtException);

    } else {
        [ARKUncaughtExceptionLogDistributors addObject:logDistributor];
    }

    [logDistributorsLock unlock];
}

void ARKDisableLogOnUncaughtException()
{
    ARKDisableLogOnUncaughtExceptionToLogDistributor([ARKLogDistributor defaultDistributor]);
}

void ARKDisableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor)
{
    NSLock *const logDistributorsLock = ARKGetUncaughtExceptionLogDistributorsLock();
    [logDistributorsLock lock];

    [ARKUncaughtExceptionLogDistributors removeObject:logDistributor];

    // If that was the last log distributor, clean up the handler.
    if ([ARKUncaughtExceptionLogDistributors count] == 0) {
        ARKSetUncaughtExceptionHandler(ARKPreviousUncaughtExceptionHandler);
        ARKPreviousUncaughtExceptionHandler = NULL;
        ARKUncaughtExceptionLogDistributors = nil;
    }

    [logDistributorsLock unlock];
}
