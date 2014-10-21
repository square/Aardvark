//
//  ARKLogController.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogController.h"
#import "ARKLogController_Testing.h"

#import "ARKLogHandler.h"
#import "ARKLogMessage.h"


@interface ARKLogController ()

@property (nonatomic, strong, readwrite) NSMutableArray *logMessages;
@property (nonatomic, strong, readonly) NSOperationQueue *loggingQueue;
@property (nonatomic, strong, readonly) NSMutableArray *logHandlers;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@end


@implementation ARKLogController

@synthesize logMessageClass = _logMessageClass;
@synthesize maximumLogMessageCount = _maximumLogMessageCount;
@synthesize maximumLogCountToPersist = _maximumLogCountToPersist;
@synthesize persistedLogsFileURL = _persistedLogsFileURL;
@synthesize logsToConsole = _logsToConsole;

#pragma mark - Class Methods

+ (instancetype)defaultController;
{
    static ARKLogController *ARKDefaultLogController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKDefaultLogController = [[[self class] alloc] _initDefaultController];
    });
    
    return ARKDefaultLogController;
}

#pragma mark - Initialization

- (instancetype)_initDefaultController;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    
    // Use setter to ensure we pick up the logs already on disk.
    self.persistedLogsFileURL = [NSURL fileURLWithPath:[[applicationSupportDirectory stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier] stringByAppendingPathComponent:@"ARKDefaultLogControllerLogMessages.data"]];
    
    return self;
}

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _logHandlers = [NSMutableArray new];
    
    // Use setters on public properties to ensure consistency.
    self.logMessageClass = [ARKLogMessage class];
    self.maximumLogMessageCount = 2000;
    self.maximumLogCountToPersist = 500;
    
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

- (Class)logMessageClass;
{
    if ([NSOperationQueue currentQueue] == self.loggingQueue) {
        return _logMessageClass;
    } else {
        __block Class logMessageClass = NULL;
        [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
            logMessageClass = _logMessageClass;
        }];
        
        return logMessageClass;
    }
}

- (void)setLogMessageClass:(Class)logMessageClass;
{
    NSAssert([logMessageClass isSubclassOfClass:[ARKLogMessage class]], @"Attempting to set a logMessageClass that is not a subclass of ARKLogMessage!");
    
    [self.loggingQueue addOperationWithBlock:^{
        if (_logMessageClass == logMessageClass) {
            return;
        }
        
        _logMessageClass = logMessageClass;
    }];
}

- (NSUInteger)maximumLogMessageCount;
{
    if ([NSOperationQueue currentQueue] == self.loggingQueue) {
        return _maximumLogMessageCount;
    } else {
        __block NSUInteger maximumLogMessageCount = 0;
        [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
            maximumLogMessageCount = _maximumLogMessageCount;
        }];
        
        return maximumLogMessageCount;
    }
}

- (void)setMaximumLogMessageCount:(NSUInteger)maximumLogCount;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (_maximumLogMessageCount == maximumLogCount) {
            return;
        }
        
        _maximumLogMessageCount = maximumLogCount;
        
        if (maximumLogCount == 0) {
            self.logMessages = nil;
        } else if (self.logMessages == nil) {
            [self _initializeLogMessages_inLoggingQueue];
        }
    }];
}

- (NSUInteger)maximumLogCountToPersist;
{
    if ([NSOperationQueue currentQueue] == self.loggingQueue) {
        return _maximumLogCountToPersist;
    } else {
        __block NSUInteger maximumLogCountToPersist = 0;
        [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
            maximumLogCountToPersist = _maximumLogCountToPersist;
        }];
        
        return maximumLogCountToPersist;
    }
}

- (void)setMaximumLogCountToPersist:(NSUInteger)maximumLogCountToPersist;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (_maximumLogCountToPersist == maximumLogCountToPersist) {
            return;
        }
        
        _maximumLogCountToPersist = maximumLogCountToPersist;
    }];
}

- (NSURL *)persistedLogsFileURL;
{
    if ([NSOperationQueue currentQueue] == self.loggingQueue) {
        return _persistedLogsFileURL;
    } else {
        __block NSURL *persistedLogsFileURL = nil;
        [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
            persistedLogsFileURL = _persistedLogsFileURL;
        }];
        
        return persistedLogsFileURL;
    }
}

- (void)setPersistedLogsFileURL:(NSURL *)persistedLogsFileURL;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (![_persistedLogsFileURL isEqual:persistedLogsFileURL]) {
            _persistedLogsFileURL = persistedLogsFileURL;
            NSArray *persistedLogs = [self _persistedLogs];
            
            [self.logMessages addObjectsFromArray:persistedLogs];
        }
    }];
}

- (BOOL)logsToConsole;
{
    if ([NSOperationQueue currentQueue] == self.loggingQueue) {
        return _logsToConsole;
    } else {
        __block BOOL logsToConsole = NO;
        [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
            logsToConsole = _logsToConsole;
        }];
        
        return logsToConsole;
    }
}

- (void)setLogsToConsole:(BOOL)logsToConsole;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (_logsToConsole != logsToConsole) {
            _logsToConsole = logsToConsole;
        }
    }];
}

#pragma mark - Public Methods - Log Handlers

- (void)addLogHandler:(id <ARKLogHandler>)logHandler;
{
    NSAssert([logHandler conformsToProtocol:@protocol(ARKLogHandler)], @"Tried to add a log handler that does not conform to ARKLogHandler protocol");
    
    [self.loggingQueue addOperationWithBlock:^{
        if (![self.logHandlers containsObject:logHandler]) {
            [self.logHandlers addObject:logHandler];
        }
    }];
}

- (void)removeLogHandler:(id <ARKLogHandler>)logHandler;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logHandlers removeObject:logHandler];
    }];
}

#pragma mark - Public Methods - Appending Logs

- (void)appendLogMessage:(ARKLogMessage *)logMessage;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (!self.loggingEnabled) {
            return;
        }
        
        [self _appendLogMessage_inLoggingQueue:logMessage];
    }];
}

- (void)appendLogWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (!self.loggingEnabled) {
            return;
        }
        
        ARKLogMessage *logMessage = [[self.logMessageClass alloc] initWithText:text image:image type:type userInfo:userInfo];
        
        [self _appendLogMessage_inLoggingQueue:logMessage];
    }];
}

- (void)appendLogWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        [self appendLogWithText:logText image:nil type:type userInfo:userInfo];
    }
}

- (void)appendLogWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self appendLogWithType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

- (void)appendLogWithFormat:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        [self appendLogWithText:logText image:nil type:ARKLogTypeDefault userInfo:nil];
    }
}

- (void)appendLogWithFormat:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self appendLogWithFormat:format arguments:argList];
    va_end(argList);
}

- (void)appendScreenshotLog;
{
    if (self.loggingEnabled) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UIGraphicsBeginImageContext(window.bounds.size);
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSString *logText = @"📷📱 Screenshot!";
        [self appendLogWithText:logText image:screenshot type:ARKLogTypeDefault userInfo:nil];
    }
}

#pragma mark - Public Methods - Accessing and Clearing Logs

- (NSArray *)allLogMessages;
{
    __block NSArray *logMessages = nil;
    
    [self _performBlockInLoggingQueueAndWaitUntilFinished:^{
        [self _trimLogs_inLoggingQueue];
        logMessages = [self.logMessages copy];
    }];
    
    return logMessages;
}

- (void)clearLogs;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logMessages removeAllObjects];
        [self _persistLogs_inLoggingQueue];
    }];
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

- (void)_performBlockInLoggingQueueAndWaitUntilFinished:(dispatch_block_t)block;
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    [self.loggingQueue addOperations:@[blockOperation] waitUntilFinished:YES];
}

- (void)_appendLogMessage_inLoggingQueue:(ARKLogMessage *)logMessage;
{
    // Don't proactively trim too often.
    if (self.maximumLogMessageCount > 0 && self.logMessages.count >= [self _maximumLogMessageCountToKeepInMemory]) {
        // We've held on to 2x more logs than we'll ever expose. Trim!
        [self _trimLogs_inLoggingQueue];
    }
    
    if (self.logsToConsole) {
        NSLog(@"%@", logMessage.text);
    }
    
    for (id <ARKLogHandler> logHandler in self.logHandlers) {
        [logHandler logController:self didAppendLogMessage:logMessage];
    }
    
    [self.logMessages addObject:logMessage];
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

- (void)_initializeLogMessages_inLoggingQueue;
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

- (void)_persistLogs_inLoggingQueue;
{
    // Perist trimmed logs when the app is backgrounded.
    NSArray *logsToPersist = [self _trimmedLogsToPersist_inLoggingQueue];
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

- (void)_trimLogs_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logMessages.count;
    if (numberOfLogs > self.maximumLogMessageCount) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogMessageCount)];
    }
}

- (NSArray *)_trimmedLogsToPersist_inLoggingQueue;
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
