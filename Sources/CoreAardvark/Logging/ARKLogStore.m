//
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
#import "AardvarkDefines.h"
#import "NSURL+ARKAdditions.h"


@interface ARKLogStore ()

/// Stores all log messages.
@property (nonnull) ARKDataArchive *dataArchive;

@end


@implementation ARKLogStore

@synthesize logDistributor = _logDistributor;

#pragma mark - Initialization

- (nullable instancetype)initWithPersistedLogFileName:(nonnull NSString *)fileName maximumLogMessageCount:(NSUInteger)maximumLogMessageCount;
{
    ARKCheckCondition(fileName.length > 0, nil, @"Must specify a file name");

    NSURL *const persistedLogFileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:fileName];
    ARKCheckCondition(persistedLogFileURL != nil, nil, @"Could not create persisted log file URL with file name %@", fileName);

    ARKDataArchive *const dataArchive = [[self class] _dataArchiveWithPersistedLogFileURL:persistedLogFileURL maximumLogMessageCount:maximumLogMessageCount];
    ARKCheckCondition(dataArchive != nil, nil, @"Could not instantiate data archive with persisted log file URL %@", persistedLogFileURL);

    self = [super init];
    if (!self) {
        return nil;
    }

    _persistedLogFileURL = persistedLogFileURL;
    _maximumLogMessageCount = maximumLogMessageCount;
    _dataArchive = dataArchive;
    _prefixNameWhenPrintingToConsole = YES;

#if !TARGET_OS_WATCH
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#endif

    return self;
}

- (nullable instancetype)initWithPersistedLogFileName:(NSString *)fileName;
{
    return [self initWithPersistedLogFileName:fileName maximumLogMessageCount:2000];
}

- (nullable instancetype)initWithPersistedLogFileURL:(nonnull NSURL *)persistedLogFileURL maximumLogMessageCount:(NSUInteger)maximumLogMessageCount;
{
    ARKDataArchive *const dataArchive = [[self class] _dataArchiveWithPersistedLogFileURL:persistedLogFileURL maximumLogMessageCount:maximumLogMessageCount];
    ARKCheckCondition(dataArchive != nil, nil, @"Could not instantiate data archive with persisted log file URL %@", persistedLogFileURL);

    self = [super init];
    if (!self) {
        return nil;
    }

    _persistedLogFileURL = [persistedLogFileURL copy];
    _maximumLogMessageCount = maximumLogMessageCount;
    _dataArchive = dataArchive;
    _prefixNameWhenPrintingToConsole = YES;

#if !TARGET_OS_WATCH
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#endif

    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ARKLogObserver

- (void)observeLogMessage:(nonnull ARKLogMessage *)logMessage;
{
    if (self.logFilterBlock && !self.logFilterBlock(logMessage)) {
        // Predicate told us we should not observe this log. Bail out.
        return;
    }
    
    if (self.printsLogsToConsole) {
        if (self.name.length > 0 && self.prefixNameWhenPrintingToConsole) {
            NSLog(@"%@: %@", self.name, logMessage.text);
        } else {
            NSLog(@"%@", logMessage.text);
        }
    }
    
    [self.dataArchive appendArchiveOfObject:logMessage];
}

- (void)processAllPendingLogsWithCompletionHandler:(nonnull dispatch_block_t)completionHandler;
{
    [self.dataArchive saveArchiveWithCompletionHandler:completionHandler];
}

#pragma mark - Public Methods

- (void)retrieveAllLogMessagesWithCompletionHandler:(nonnull void (^)(NSArray<ARKLogMessage *> *logMessages))completionHandler;
{
    ARKCheckCondition(completionHandler != NULL, , @"Can not retrieve log messages without a completion handler");
    if (self.logDistributor == nil) {
        completionHandler(nil);
        ARKCheckCondition(NO, , @"Can not retrieve log messages without a log distributor");
    }
    
    // Ensure we observe all log messages that have been queued by the distributor before we retrieve the our logs.
    [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
        [self.dataArchive readObjectsFromArchiveOfType:[ARKLogMessage class] completionHandler:^(NSArray *unarchivedObjects) {
            completionHandler(unarchivedObjects);
        }];
    }];
}

- (void)clearLogsWithCompletionHandler:(nullable dispatch_block_t)completionHandler;
{
    if (self.logDistributor == nil) {
        [self.dataArchive clearArchiveWithCompletionHandler:completionHandler];
    } else {
        [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
            [self.dataArchive clearArchiveWithCompletionHandler:completionHandler];
        }];
    }
}

- (void)waitUntilAllLogsAreConsumedAndArchiveSaved;
{
    [self.logDistributor waitUntilAllPendingLogsHaveBeenDistributed];
    [self.dataArchive saveArchiveAndWait:YES];
}

#pragma mark - Private Methods

- (void)_applicationWillTerminate:(nullable NSNotification *)notification;
{
    [self waitUntilAllLogsAreConsumedAndArchiveSaved];
}

#pragma mark - Private Static Methods

+ (ARKDataArchive *)_dataArchiveWithPersistedLogFileURL:(nonnull NSURL *)persistedLogFileURL maximumLogMessageCount:(NSUInteger)maximumLogMessageCount;
{
    ARKCheckCondition(maximumLogMessageCount > 0, nil, @"maximumLogMessageCount must be greater than zero");

    return [[ARKDataArchive alloc] initWithURL:persistedLogFileURL maximumObjectCount:maximumLogMessageCount trimmedObjectCount:0.5 * maximumLogMessageCount];
}

@end
