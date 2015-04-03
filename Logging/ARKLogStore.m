//
//  ARKLogStore.m
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
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

#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"

#import "ARKDataArchive.h"
#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Protected.h"
#import "ARKLogMessage.h"
#import "NSURL+ARKAdditions.h"


@interface ARKLogStore ()

/// Stores all log messages.
@property (strong) ARKDataArchive *dataArchive;

@end


@implementation ARKLogStore

@synthesize logDistributor = _logDistributor;

#pragma mark - Initialization

- (instancetype)init;
{
    ARKCheckCondition(NO, nil, @"Must use -initWithPersistedLogFileName: to initialize a ARKLogStore");
}

- (instancetype)initWithPersistedLogFileName:(NSString *)fileName maximumLogMessageCount:(NSUInteger)maximumLogMessageCount;
{
    ARKCheckCondition(fileName.length > 0, nil, @"Must specify a file name");
    ARKCheckCondition(maximumLogMessageCount > 0, nil, @"maximumLogMessageCount must be greater than zero");
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _persistedLogFileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:fileName];
    _maximumLogMessageCount = maximumLogMessageCount;
    _dataArchive = [[ARKDataArchive alloc] initWithURL:self.persistedLogFileURL maximumObjectCount:maximumLogMessageCount trimmedObjectCount:0.5 * maximumLogMessageCount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (instancetype)initWithPersistedLogFileName:(NSString *)fileName __attribute__((nonnull(1)));
{
    return [self initWithPersistedLogFileName:fileName maximumLogMessageCount:2000];
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ARKLogDistributor

- (void)observeLogMessage:(ARKLogMessage *)logMessage;
{
    if (self.logFilterBlock && !self.logFilterBlock(logMessage)) {
        // Predicate told us we should not observe this log. Bail out.
        return;
    }
    
    if (self.printsLogsToConsole) {
        if (self.name.length) {
            NSLog(@"%@: %@", self.name, logMessage.text);
        } else {
            NSLog(@"%@", logMessage.text);
        }
    }
    
    [self.dataArchive appendArchiveOfObject:logMessage];
}

#pragma mark - Public Methods

- (void)retrieveAllLogMessagesWithCompletionHandler:(void (^)(NSArray *logMessages))completionHandler;
{
    ARKCheckCondition(completionHandler != NULL, , @"Can not retrieve log messages without a completion handler");
    if (self.logDistributor == nil) {
        completionHandler(nil);
        ARKCheckCondition(NO, , @"Can not retrieve log messages without a log distributor");
    }
    
    // Ensure we observe all log messages that have been queued by the distributor before we retrieve the our logs.
    [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
        [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
            completionHandler(unarchivedObjects);
        }];
    }];
}

- (void)clearLogsWithCompletionHandler:(dispatch_block_t)completionHandler;
{
    if (self.logDistributor == nil) {
        [self.dataArchive clearArchiveWithCompletionHandler:completionHandler];
    } else {
        [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
            [self.dataArchive clearArchiveWithCompletionHandler:completionHandler];
        }];
    }
}

#pragma mark - Private Methods

- (void)_applicationWillTerminate:(NSNotification *)notification;
{
    [self.logDistributor waitUntilAllPendingLogsHaveBeenDistributed];
    [self.dataArchive saveArchiveAndWait:YES];
}

@end
