//
//  ARKLogController.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogController.h"
#import "ARKLogController_Testing.h"

#import "ARKAardvarkLog.h"


NSString *const ARKLogsFileName = @"ARKLogs";


@interface ARKLogController ()

@property (nonatomic, strong, readwrite) NSMutableArray *logs;
@property (nonatomic, strong, readonly) NSOperationQueue *loggingQueue;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@end


@implementation ARKLogController

#pragma mark - Class Methods

+ (instancetype)sharedInstance;
{
    static ARKLogController *ARKDefaultLogController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKDefaultLogController = [[self class] new];
    });
    
    return ARKDefaultLogController;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone;
{
#if AARDVARK_LOG_ENABLED
    return [super allocWithZone:zone];
#else
    return nil;
#endif
}

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _maximumLogCount = 2000;
    _maximumLogCountToPersist = 500;
    
    NSArray *persistedLogs = [self _persistedLogs];
    if (persistedLogs.count > 0) {
        _logs = [persistedLogs mutableCopy];
    } else {
        _logs = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogCount)];
    }
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;
    
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)]) {
        // iOS 8 API
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)appendLog:(ARKAardvarkLog *)log;
{
    [self.loggingQueue addOperationWithBlock:^{
        // Don't proactively trim too often.
        if (self.logs.count >= 2 * self.maximumLogCount) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLoggingQueue];
        }
        
        [self.logs addObject:log];
    }];
}

- (NSArray *)allLogs;
{
    __block NSArray *logs = nil;
    
    [self.loggingQueue addOperationWithBlock:^{
        [self _trimLogs_inLoggingQueue];
        
        logs = [self.logs copy];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
    
    return logs;
}

- (void)clearLocalLogs;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logs removeAllObjects];
        [self _persistLogs_inLoggingQueue];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
{
    self.persistLogsBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
    }];
    
    [self.loggingQueue addOperationWithBlock:^{
        [self _persistLogs_inLoggingQueue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
        });
    }];
}

- (NSString *)_pathToPersistedLogs;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    
    return [applicationSupportDirectory stringByAppendingPathComponent:ARKLogsFileName];
}

- (NSArray *)_persistedLogs;
{
    NSString *filePath = [self _pathToPersistedLogs];
    NSData *persistedLogData = [[NSFileManager defaultManager] contentsAtPath:filePath];
    NSArray *persistedLogs = persistedLogData ? [NSKeyedUnarchiver unarchiveObjectWithData:persistedLogData] : nil;
    if ([persistedLogs isKindOfClass:[NSArray class]] && persistedLogs.count > 0) {
        return persistedLogs;
    }
    
    return nil;
}

- (void)_persistLogs_inLoggingQueue;
{
    // Perist trimmed logs when the app is backgrounded.
    NSArray *logsToPersist = [self _trimedLogsToPersist_inLoggingQueue];
    NSString *filePath = [self _pathToPersistedLogs];
    
    if (logsToPersist.count == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    } else {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSKeyedArchiver archivedDataWithRootObject:logsToPersist] attributes:nil];
    }
}

- (void)_trimLogs_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logs.count;
    if (numberOfLogs > self.maximumLogCount) {
        [self.logs removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCount)];
    }
}

- (NSArray *)_trimedLogsToPersist_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logs.count;
    if (numberOfLogs > self.maximumLogCountToPersist) {
        NSMutableArray *logsToPersist = [self.logs mutableCopy];
        [logsToPersist removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCountToPersist)];
        return [logsToPersist copy];
    }
    
    return [self.logs copy];
}

@end
