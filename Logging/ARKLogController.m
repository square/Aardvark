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
@property (nonatomic, strong, readonly) NSMutableSet *logHandlers;
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
    
    return self;
}

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logMessageClass = [ARKLogMessage class];
    _maximumLogMessageCount = 2000;
    _maximumLogCountToPersist = 500;
    
    _logMessages = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogMessageCount)];
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _logHandlers = [NSMutableSet new];
    
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
    
    [self.loggingQueue addOperationWithBlock:^{
        _logMessageClass = logMessageClass;
    }];
}

- (void)setMaximumLogMessageCount:(NSUInteger)maximumLogCount;
{
    if (_maximumLogMessageCount == maximumLogCount) {
        return;
    }
    
    _maximumLogMessageCount = maximumLogCount;
    
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

#pragma mark - Public Methods - Log Handlers

- (void)addLogHandler:(id <ARKLogHandler>)logHandler;
{
    NSAssert([logHandler conformsToProtocol:@protocol(ARKLogHandler)], @"Tried to add a log handler that does not conform to ARKLogHandler protocol");
    
    [self.loggingQueue addOperationWithBlock:^{
        [self.logHandlers addObject:logHandler];
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

- (void)_appendLogMessage_inLoggingQueue:(ARKLogMessage *)logMessage;
{
    // Don't proactively trim too often.
    if (self.maximumLogMessageCount > 0 && self.logMessages.count >= 2 * self.maximumLogMessageCount) {
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
        if (persistedLogs.count > self.maximumLogMessageCount) {
            NSUInteger numberOfLogsToTrim = persistedLogs.count - self.maximumLogMessageCount;
            self.logMessages = [[persistedLogs subarrayWithRange:NSMakeRange(numberOfLogsToTrim, self.maximumLogMessageCount)] mutableCopy];
        } else {
            self.logMessages = [persistedLogs mutableCopy];
        }
    } else {
        self.logMessages = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogMessageCount)];
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
    if (numberOfLogs > self.maximumLogMessageCount) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogMessageCount)];
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
