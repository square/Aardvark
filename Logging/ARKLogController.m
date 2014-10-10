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
#import "ARKLogger.h"


@interface ARKLogController ()

@property (nonatomic, strong, readwrite) NSMutableArray *logs;
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
        ARKDefaultLogController = [[self class] new];
    });
    
    return ARKDefaultLogController;
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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    _pathToPersistedLogs = [[applicationSupportDirectory stringByAppendingPathComponent:@"ARKLogControllerLogs.data"] copy];
    
    NSArray *persistedLogs = [self _persistedLogs];
    if (persistedLogs.count > 0) {
        _logs = [persistedLogs mutableCopy];
    } else {
        _logs = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogCount)];
    }
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _globalLoggers = [NSMutableSet new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (void)dealloc
{
    [self.loggingQueue addOperationWithBlock:^{
        [self _persistLogs_inLoggingQueue];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)appendAardvarkLog:(ARKAardvarkLog *)log;
{
    [self.loggingQueue addOperationWithBlock:^{
        if (!self.loggingEnabled) {
            return;
        }
        
        // Don't proactively trim too often.
        if (self.logs.count >= 2 * self.maximumLogCount) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLoggingQueue];
        }
        
        if (self.logToConsole) {
            NSLog(@"%@", log.text);
        }
        
        [self.logs addObject:log];
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

- (void)clearLogs;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logs removeAllObjects];
        [self _persistLogs_inLoggingQueue];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
}

- (void)setPathToPersistedLogs:(NSString *)pathToPersistedLogs;
{
    if (![_pathToPersistedLogs isEqualToString:pathToPersistedLogs]) {
        _pathToPersistedLogs = pathToPersistedLogs;
        NSArray *persistedLogs = [self _persistedLogs];
        [self.logs addObjectsFromArray:persistedLogs];
    }
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

- (NSArray *)_persistedLogs;
{
    NSData *persistedLogData = [[NSFileManager defaultManager] contentsAtPath:self.pathToPersistedLogs];
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
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    if (logsToPersist.count == 0) {
        [defaultManager removeItemAtPath:self.pathToPersistedLogs error:NULL];
    } else {
        if ([defaultManager createDirectoryAtPath:[self.pathToPersistedLogs stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL]) {
            [defaultManager createFileAtPath:self.pathToPersistedLogs contents:[NSKeyedArchiver archivedDataWithRootObject:logsToPersist] attributes:nil];
        } else {
            NSLog(@"ERROR! Could not persist logs.");
        }
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


@implementation ARKLogController (ARKLogAdditions)

- (void)appendLog:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:ARKLogTypeDefault];
        [self appendAardvarkLog:log];
    }
}

- (void)appendLogType:(ARKLogType)type format:(NSString *)format arguments:(va_list)argList;
{
    if (self.loggingEnabled) {
        NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:nil type:type];
        [self appendAardvarkLog:log];
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
        ARKAardvarkLog *log = [[ARKAardvarkLog alloc] initWithText:logText image:screenshot type:ARKLogTypeDefault];
        [self appendAardvarkLog:log];
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

- (void)appendLogType:(ARKLogType)type format:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [[ARKLogController defaultController] appendLogType:type format:format arguments:argList];
    va_end(argList);
}

@end
