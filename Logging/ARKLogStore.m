//
//  ARKLogStore.m
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"

#import "ARKLogDistributor.h"
#import "ARKLogMessage.h"


@interface ARKLogStore ()

@property (nonatomic, strong, readonly) NSOperationQueue *logObservingQueue;

/// Stores all log messages. Must be accessed only from the log observing queue.
@property (nonatomic, strong, readwrite) NSMutableArray *logMessages;

/// Background task identifier for persisting logs to disk. Must be accessed only from the main queue.
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@property (atomic, assign, readwrite) NSUInteger internalMaximumLogMessageCount;
@property (atomic, copy, readwrite) NSURL *internalPersistedLogsFileURL;

@end


@implementation ARKLogStore

@synthesize logDistributor = _logDistributor;

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logObservingQueue = [NSOperationQueue new];
    _logObservingQueue.name = [NSString stringWithFormat:@"%@ Log Observing Queue", self];
    _logObservingQueue.maxConcurrentOperationCount = 1;
    
#ifdef __IPHONE_8_0
    if ([_logObservingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _logObservingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _internalMaximumLogMessageCount = 2000;
    [self _initializeLogMessages_inLogObservingQueue];
    
    _maximumLogCountToPersist = 500;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (instancetype)initWithPersistedLogFileName:(NSString *)fileName;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.persistedLogsFileURL = [self _persistenceURLWithFileName:fileName];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Force our log distributor to nil so persisting logs does not wait on the distributor.
    _logDistributor = nil;
    
    // Persist the logs on whatever thread we're on.
    [self _persistLogs_inLogObservingQueue];
}

#pragma mark - Properties

- (NSUInteger)maximumLogMessageCount;
{
    return self.internalMaximumLogMessageCount;
}

- (void)setMaximumLogMessageCount:(NSUInteger)maximumLogCount;
{
    self.internalMaximumLogMessageCount = maximumLogCount;
    
    [self.logObservingQueue addOperationWithBlock:^{
        if (maximumLogCount == 0) {
            self.logMessages = nil;
        } else if (self.logMessages == nil) {
            [self _initializeLogMessages_inLogObservingQueue];
        }
    }];
}

- (NSURL *)persistedLogsFileURL;
{
    return self.internalPersistedLogsFileURL;
}

- (void)setPersistedLogsFileURL:(NSURL *)persistedLogsFileURL;
{
    if ([self.internalPersistedLogsFileURL isEqual:persistedLogsFileURL]) {
        return;
    }
    
    self.internalPersistedLogsFileURL = persistedLogsFileURL;
    [self.logObservingQueue addOperationWithBlock:^{
        [self.logMessages addObjectsFromArray:[self _persistedLogs]];
    }];
}

#pragma mark - ARKLogDistributor

- (void)observeLogMessage:(ARKLogMessage *)logMessage;
{
    [self.logObservingQueue addOperationWithBlock:^{
        if (self.logFilterBlock && !self.logFilterBlock(logMessage)) {
            // Predicate told us we should not observe this log. Bail out.
            return;
        }
        
        // Don't proactively trim too often.
        if (self.maximumLogMessageCount > 0 && self.logMessages.count >= [self _maximumLogMessageCountToKeepInMemory]) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLogObservingQueue];
        }
        
        if (self.logsToConsole) {
            if (self.name.length) {
                NSLog(@"%@: %@", self.name, logMessage.text);
            } else {
                NSLog(@"%@", logMessage.text);
            }
        }
        
        [self.logMessages addObject:logMessage];
    }];
}

#pragma mark - Public Methods

- (void)retrieveAllLogMessagesWithCompletionHandler:(void (^)(NSArray *logMessages))completionHandler;
{
    ARKCheckCondition(completionHandler, , @"Can not retrieve log messages without a completion handler");
    if (!self.logDistributor) {
        completionHandler(nil);
        ARKCheckCondition(NO, , @"Can not retrieve log messages without a log distributor");
    }
    
    // Ensure we observe all log messages that have been queued by the distributor before we retrieve the our logs.
    [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
        [self.logObservingQueue addOperationWithBlock:^{
            [self _trimLogs_inLogObservingQueue];
            if (completionHandler) {
                NSArray *logMessages = [self.logMessages copy];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(logMessages);
                }];
            }
        }];
    }];
}

- (void)clearLogs;
{
    [self.logObservingQueue addOperationWithBlock:^{
        [self.logMessages removeAllObjects];
        [self _persistLogs_inLogObservingQueue];
    }];
}

#pragma mark - Private Methods

- (void)_applicationWillResignActiveNotification:(NSNotification *)notification;
{
    self.persistLogsBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
    }];
    
    [self.logObservingQueue addOperationWithBlock:^{
        [self _persistLogs_inLogObservingQueue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
        });
    }];
}

- (NSArray *)_persistedLogs;
{
    NSData *persistedLogData = [NSData dataWithContentsOfURL:self.persistedLogsFileURL];
    NSArray *persistedLogs = persistedLogData ? [NSKeyedUnarchiver unarchiveObjectWithData:persistedLogData] : nil;
    if ([persistedLogs isKindOfClass:[NSArray class]] && persistedLogs.count > 0) {
        return persistedLogs;
    }
    
    return nil;
}

- (void)_initializeLogMessages_inLogObservingQueue;
{
    NSArray *persistedLogs = [self _persistedLogs];
    if (persistedLogs.count > 0) {
        if (persistedLogs.count > self.maximumLogMessageCount) {
            NSUInteger numberOfLogsToTrim = persistedLogs.count - self.maximumLogMessageCount;
            self.logMessages = [[persistedLogs subarrayWithRange:NSMakeRange(numberOfLogsToTrim, self.maximumLogMessageCount)] mutableCopy];
        } else {
            self.logMessages = [persistedLogs mutableCopy];
        }
    } else {
        self.logMessages = [[NSMutableArray alloc] initWithCapacity:[self _maximumLogMessageCountToKeepInMemory]];
    }
}

- (void)_persistLogs_inLogObservingQueue;
{
    if (!self.persistedLogsFileURL) {
        return;
    }
    
    [self _trimmedLogsToPersist_inLogObservingQueue:^(NSArray *logsToPersist) {
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        
        if (logsToPersist.count == 0) {
            [defaultManager removeItemAtURL:self.persistedLogsFileURL error:NULL];
        } else {
            if ([defaultManager createDirectoryAtURL:[self.persistedLogsFileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL]) {
                [[NSKeyedArchiver archivedDataWithRootObject:logsToPersist] writeToURL:self.persistedLogsFileURL atomically:YES];
            }
        }
    }];
}

- (void)_trimLogs_inLogObservingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogMessageCount) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogMessageCount)];
    }
}

- (void)_trimmedLogsToPersist_inLogObservingQueue:(void (^)(NSArray *logsToPersist))completionHandler;
{
    dispatch_block_t trimLogsBlock_inLogObservingQueue = ^{
        [self _trimLogs_inLogObservingQueue];
        
        if (completionHandler) {
            NSUInteger numberOfLogs = self.logMessages.count;
            if (numberOfLogs > self.maximumLogCountToPersist) {
                NSMutableArray *logsToPersist = [self.logMessages mutableCopy];
                [logsToPersist removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCountToPersist)];
                completionHandler([logsToPersist copy]);
                
            } else {
                completionHandler([self.logMessages copy]);
            }
        }
    };
    
    if (self.logDistributor) {
        // Ensure we observe all log messages that have been queued by the distributor before we retrieve the our logs.
        [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
            [self.logObservingQueue addOperationWithBlock:^{
                trimLogsBlock_inLogObservingQueue();
            }];
        }];
    } else {
        trimLogsBlock_inLogObservingQueue();
    }
}

- (NSUInteger)_maximumLogMessageCountToKeepInMemory;
{
    return 2 * self.maximumLogMessageCount;
}

- (NSURL *)_persistenceURLWithFileName:(NSString *)fileName;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *persistenceLogsPath = [[applicationSupportDirectory stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:persistenceLogsPath isDirectory:NO];
}

@end
