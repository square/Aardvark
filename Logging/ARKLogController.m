//
//  ARKLogController.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogController.h"
#import "ARKLogController_Testing.h"

#import "ARKLogger.h"
#import "ARKLogMessage.h"


@interface ARKLogController ()

@property (nonatomic, strong, readwrite) NSMutableArray *logMessages;
@property (nonatomic, strong, readonly) NSMutableDictionary *logBlocks;
@property (nonatomic, strong, readonly) NSOperationQueue *loggingQueue;
@property (nonatomic, strong, readonly) NSMutableSet *globalLoggers;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@end


@implementation ARKLogController

#pragma mark - Class Methods

+ (instancetype)defaultController;
{
    static ARKLogController *ARKDefaultLogController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKDefaultLogController = [[[self class] alloc] initDefaultController];
    });
    
    return ARKDefaultLogController;
}

#pragma mark - Initialization

- (instancetype)initDefaultController;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    _persistedLogsFilePath = [[[applicationSupportDirectory stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier] stringByAppendingPathComponent:@"ARKDefaultLogControllerLogMessages.data"] copy];
    
    // Initialize logMessages. This can be done on this thread since we are still inside of init.
    [self _initializeLogMessages_inLoggingQueue];
    
    _logBlocks = [NSMutableDictionary new];
    
    return self;
}

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logMessageClass = [ARKLogMessage class];
    _maximumLogCount = 2000;
    _maximumLogCountToPersist = 500;
    
    _logMessages = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogCount)];
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _globalLoggers = [NSMutableSet new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // We're guaranteed that no one is logging to us since we're in dealloc. Persist the logs on whatever thread we're on.
    [self _persistLogs_inLoggingQueue];
}

#pragma mark - Properties

- (void)setLogMessageClass:(Class)logMessageClass;
{
    NSAssert([logMessageClass isSubclassOfClass:[ARKLogMessage class]], @"Attempting to set a logMessageClass that is not a subclass of ARKLogMessage!");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logMessageClass = logMessageClass;
    });
}

- (void)setMaximumLogCount:(NSUInteger)maximumLogCount;
{
    if (_maximumLogCount == maximumLogCount) {
        return;
    }
    
    _maximumLogCount = maximumLogCount;
    
    [self.loggingQueue addOperationWithBlock:^{
        if (maximumLogCount == 0) {
            self.logMessages = nil;
        } else if (self.logMessages == nil) {
            [self _initializeLogMessages_inLoggingQueue];
        }
    }];
}

- (void)setPersistedLogsFilePath:(NSString *)persistedLogsFilePath;
{
    if (![_persistedLogsFilePath isEqualToString:persistedLogsFilePath]) {
        _persistedLogsFilePath = persistedLogsFilePath;
        NSArray *persistedLogs = [self _persistedLogs];
        
        [self.loggingQueue addOperationWithBlock:^{
            [self.logMessages addObjectsFromArray:persistedLogs];
        }];
    }
}

#pragma mark - Public Methods

- (void)addLogBlock:(ARKLogBlock)logBlock withKey:(id <NSCopying>)logBlockKey;
{
    NSAssert(logBlock, @"Can not add NULL logBlock");
    NSAssert(logBlockKey, @"Can not add logBlock with nil key");
    
    [self.loggingQueue addOperationWithBlock:^{
        self.logBlocks[logBlockKey] = logBlock;
    }];
}

- (void)removeLogBlockWithKey:(id <NSCopying>)logBlockKey;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logBlocks removeObjectForKey:logBlockKey];
    }];
}

- (void)appendLogMessage:(ARKLogMessage *)logMessage;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (!self.loggingEnabled) {
            return;
        }
        
        // Don't proactively trim too often.
        if (self.maximumLogCount > 0 && self.logMessages.count >= 2 * self.maximumLogCount) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLoggingQueue];
        }
        
        if (self.logToConsole) {
            NSLog(@"%@", logMessage.text);
        }
        
        for (ARKLogBlock logBlock in self.logBlocks.allValues) {
            logBlock(logMessage.text, logMessage.userInfo);
        }
        
        [self.logMessages addObject:logMessage];
    }];
}

- (void)addLogger:(id <ARKLogger>)logger;
{
    NSAssert([logger conformsToProtocol:@protocol(ARKLogger)], @"Tried to add a logger that does not conform to ARKLogger protocol");
    NSAssert(logger.logController == self, @"Trying add a logger whose logController does not match");
    
    @synchronized(self) {
        [self.globalLoggers addObject:logger];
    }
}

- (void)removeLogger:(id <ARKLogger>)logger;
{
    @synchronized(self) {
        [self.globalLoggers removeObject:logger];
    }
}

- (NSArray *)allLogMessages;
{
    __block NSArray *logMessages = nil;
    
    [self.loggingQueue addOperationWithBlock:^{
        [self _trimLogs_inLoggingQueue];
        
        logMessages = [self.logMessages copy];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
    
    return logMessages;
}

- (void)clearLogs;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logMessages removeAllObjects];
        [self _persistLogs_inLoggingQueue];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

- (void)_applicationWillResignActiveNotification:(NSNotification *)notification;
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

- (NSArray *)_persistedLogs;
{
    NSData *persistedLogData = [[NSFileManager defaultManager] contentsAtPath:self.persistedLogsFilePath];
    NSArray *persistedLogs = persistedLogData ? [NSKeyedUnarchiver unarchiveObjectWithData:persistedLogData] : nil;
    if ([persistedLogs isKindOfClass:[NSArray class]] && persistedLogs.count > 0) {
        return persistedLogs;
    }
    
    return nil;
}

- (void)_initializeLogMessages_inLoggingQueue;
{
    NSArray *persistedLogs = [self _persistedLogs];
    if (persistedLogs.count > 0) {
        if (persistedLogs.count > self.maximumLogCount) {
            NSUInteger numberOfLogsToTrim = persistedLogs.count - self.maximumLogCount;
            self.logMessages = [[persistedLogs subarrayWithRange:NSMakeRange(numberOfLogsToTrim, self.maximumLogCount)] mutableCopy];
        } else {
            self.logMessages = [persistedLogs mutableCopy];
        }
    } else {
        self.logMessages = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogCount)];
    }
}

- (void)_persistLogs_inLoggingQueue;
{
    // Perist trimmed logs when the app is backgrounded.
    NSArray *logsToPersist = [self _trimedLogsToPersist_inLoggingQueue];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    if (logsToPersist.count == 0) {
        [defaultManager removeItemAtPath:self.persistedLogsFilePath error:NULL];
    } else {
        BOOL persistedLogs = NO;
        if ([defaultManager createDirectoryAtPath:[self.persistedLogsFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL]) {
            persistedLogs = [defaultManager createFileAtPath:self.persistedLogsFilePath contents:[NSKeyedArchiver archivedDataWithRootObject:logsToPersist] attributes:nil];
        }
        
        if (!persistedLogs) {
            NSLog(@"ERROR! Could not persist logs.");
        }
    }
}

- (void)_trimLogs_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogCount) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCount)];
    }
}

- (NSArray *)_trimedLogsToPersist_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogCountToPersist) {
        NSMutableArray *logsToPersist = [self.logMessages mutableCopy];
        [logsToPersist removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCountToPersist)];
        return [logsToPersist copy];
    }
    
    return [self.logMessages copy];
}

@end


@implementation ARKLogController (ARKLogAdditions)

- (void)appendLog:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKLogMessage *logMessage = [[self.logMessageClass alloc] initWithText:logText image:nil type:ARKLogTypeDefault userInfo:nil];
        [self appendLogMessage:logMessage];
    }
}

- (void)appendLogType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKLogMessage *logMessage = [[self.logMessageClass alloc] initWithText:logText image:nil type:type userInfo:userInfo];
        [self appendLogMessage:logMessage];
    }
}

- (void)appendLogScreenshot;
{
    if (self.loggingEnabled) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UIGraphicsBeginImageContext(window.bounds.size);
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSString *logText = @"📷📱 Screenshot!";
        ARKLogMessage *log = [[self.logMessageClass alloc] initWithText:logText image:screenshot type:ARKLogTypeDefault userInfo:nil];
        [self appendLogMessage:log];
    }
}

@end


@implementation ARKLogController (ARKLoggerAdditions)

- (void)appendLog:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self appendLog:format arguments:argList];
    va_end(argList);
}

- (void)appendLogType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self appendLogType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

@end
