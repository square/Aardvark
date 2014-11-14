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
#import "NSOperationQueue+ARKAdditions.h"


NSString *const ARKLogConsumerRequiresAllPendingLogsNotification = @"ARKLogConsumerRequiresAllPendingLogs";


@interface ARKLogStore ()

@property (nonatomic, strong, readwrite) NSMutableArray *logMessages;
@property (nonatomic, strong, readonly) NSOperationQueue *logConsumingQueue;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@end


@implementation ARKLogStore

@synthesize name = _name;
@synthesize maximumLogMessageCount = _maximumLogMessageCount;
@synthesize maximumLogCountToPersist = _maximumLogCountToPersist;
@synthesize persistedLogsFileURL = _persistedLogsFileURL;
@synthesize consumeLogPredicate = _consumeLogPredicate;
@synthesize logsToConsole = _logsToConsole;

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logConsumingQueue = [NSOperationQueue new];
    _logConsumingQueue.maxConcurrentOperationCount = 1;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_logConsumingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _logConsumingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    // Use setters on public properties to ensure consistency.
    self.maximumLogMessageCount = 2000;
    self.maximumLogCountToPersist = 500;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // We're guaranteed that no one is logging to us since we're in dealloc. Set our log consuming queue to be the current queue to ensure property access is instant.
    _logConsumingQueue = [NSOperationQueue currentQueue];
    
    // Persist the logs on whatever thread we're on.
    [self _persistLogs_inLogConsumingQueue];
}

#pragma mark - Properties

- (NSString *)name;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _name;
    } else {
        __block NSString *name = nil;
        [self.logConsumingQueue performOperationWithBlock:^{
            name = _name;
        } waitUntilFinished:YES];
        
        return name;
    }
}

- (void)setName:(NSString *)name;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (![_name isEqualToString:name]) {
            _name = [name copy];
        }
    }];
}

- (NSUInteger)maximumLogMessageCount;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _maximumLogMessageCount;
    } else {
        __block NSUInteger maximumLogMessageCount = 0;
        [self.logConsumingQueue performOperationWithBlock:^{
            maximumLogMessageCount = _maximumLogMessageCount;
        } waitUntilFinished:YES];
        
        return maximumLogMessageCount;
    }
}

- (void)setMaximumLogMessageCount:(NSUInteger)maximumLogCount;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (_maximumLogMessageCount == maximumLogCount) {
            return;
        }
        
        _maximumLogMessageCount = maximumLogCount;
        
        if (maximumLogCount == 0) {
            self.logMessages = nil;
        } else if (self.logMessages == nil) {
            [self _initializeLogMessages_inLogConsumingQueue];
        }
    }];
}

- (NSUInteger)maximumLogCountToPersist;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _maximumLogCountToPersist;
    } else {
        __block NSUInteger maximumLogCountToPersist = 0;
        [self.logConsumingQueue performOperationWithBlock:^{
            maximumLogCountToPersist = _maximumLogCountToPersist;
        } waitUntilFinished:YES];
        
        return maximumLogCountToPersist;
    }
}

- (void)setMaximumLogCountToPersist:(NSUInteger)maximumLogCountToPersist;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (_maximumLogCountToPersist == maximumLogCountToPersist) {
            return;
        }
        
        _maximumLogCountToPersist = maximumLogCountToPersist;
    }];
}

- (NSURL *)persistedLogsFileURL;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _persistedLogsFileURL;
    } else {
        __block NSURL *persistedLogsFileURL = nil;
        [self.logConsumingQueue performOperationWithBlock:^{
            persistedLogsFileURL = _persistedLogsFileURL;
        } waitUntilFinished:YES];
        
        return persistedLogsFileURL;
    }
}

- (void)setPersistedLogsFileURL:(NSURL *)persistedLogsFileURL;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (![_persistedLogsFileURL isEqual:persistedLogsFileURL]) {
            _persistedLogsFileURL = persistedLogsFileURL;
            NSArray *persistedLogs = [self _persistedLogs];
            
            [self.logMessages addObjectsFromArray:persistedLogs];
        }
    }];
}

- (BOOL)logsToConsole;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _logsToConsole;
    } else {
        __block BOOL logsToConsole = NO;
        [self.logConsumingQueue performOperationWithBlock:^{
            logsToConsole = _logsToConsole;
        } waitUntilFinished:YES];
        
        return logsToConsole;
    }
}

- (void)setLogsToConsole:(BOOL)logsToConsole;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (_logsToConsole != logsToConsole) {
            _logsToConsole = logsToConsole;
        }
    }];
}

- (ARKConsumeLogPredicateBlock)consumeLogPredicate;
{
    if ([NSOperationQueue currentQueue] == self.logConsumingQueue) {
        return _consumeLogPredicate;
    } else {
        __block ARKConsumeLogPredicateBlock consumeLogPredicate = NULL;
        [self.logConsumingQueue performOperationWithBlock:^{
            consumeLogPredicate = _consumeLogPredicate;
        } waitUntilFinished:YES];
        
        return consumeLogPredicate;
    }
}

- (void)setConsumeLogPredicate:(ARKConsumeLogPredicateBlock)consumeLogPredicate;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (_consumeLogPredicate == consumeLogPredicate) {
            return;
        }
        
        _consumeLogPredicate = [consumeLogPredicate copy];
    }];
}

#pragma mark - ARKLogDistributor

- (void)consumeLogMessage:(ARKLogMessage *)logMessage;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        if (self.consumeLogPredicate && !self.consumeLogPredicate(logMessage)) {
            // Predicate told us we should not consume this log. Bail out.
            return;
        }
        
        // Don't proactively trim too often.
        if (self.maximumLogMessageCount > 0 && self.logMessages.count >= [self _maximumLogMessageCountToKeepInMemory]) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLogConsumingQueue];
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

- (NSArray *)allLogMessages;
{
    // Ensure we consume all log messages that have been queued by the distributor before we retrieve the our logs.
    [[NSNotificationCenter defaultCenter] postNotificationName:ARKLogConsumerRequiresAllPendingLogsNotification object:self];
    
    __block NSArray *logMessages = nil;
    
    [self.logConsumingQueue performOperationWithBlock:^{
        [self _trimLogs_inLogConsumingQueue];
        logMessages = [self.logMessages copy];
    } waitUntilFinished:YES];
    
    return logMessages;
}

- (void)clearLogs;
{
    [self.logConsumingQueue addOperationWithBlock:^{
        [self.logMessages removeAllObjects];
        [self _persistLogs_inLogConsumingQueue];
    }];
}

#pragma mark - Private Methods

- (void)_applicationWillResignActiveNotification:(NSNotification *)notification;
{
    self.persistLogsBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
    }];
    
    [self.logConsumingQueue addOperationWithBlock:^{
        [self _persistLogs_inLogConsumingQueue];
        
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

- (void)_initializeLogMessages_inLogConsumingQueue;
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

- (void)_persistLogs_inLogConsumingQueue;
{
    if (!self.persistedLogsFileURL) {
        return;
    }
    
    // Perist trimmed logs when the app is backgrounded.
    NSArray *logsToPersist = [self _trimmedLogsToPersist_inLogConsumingQueue];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    if (logsToPersist.count == 0) {
        [defaultManager removeItemAtURL:self.persistedLogsFileURL error:NULL];
    } else {
        BOOL persistedLogs = NO;
        if ([defaultManager createDirectoryAtURL:[self.persistedLogsFileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL]) {
            persistedLogs = [[NSKeyedArchiver archivedDataWithRootObject:logsToPersist] writeToURL:self.persistedLogsFileURL atomically:YES];
        }
        
        if (!persistedLogs) {
            NSLog(@"ERROR! Could not persist logs.");
        }
    }
}

- (void)_trimLogs_inLogConsumingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogMessageCount) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogMessageCount)];
    }
}

- (NSArray *)_trimmedLogsToPersist_inLogConsumingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogCountToPersist) {
        NSMutableArray *logsToPersist = [self.logMessages mutableCopy];
        [logsToPersist removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCountToPersist)];
        return [logsToPersist copy];
    }
    
    return [self.logMessages copy];
}

- (NSUInteger)_maximumLogMessageCountToKeepInMemory;
{
    return 2 * self.maximumLogMessageCount;
}

@end
