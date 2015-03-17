//
//  ARKLogDistributor.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"

#import "ARKLogMessage.h"
#import "ARKLogObserver.h"
#import "ARKLogStore.h"


@interface ARKLogDistributor ()

@property (nonatomic, strong, readonly) NSOperationQueue *logDistributingQueue;
@property (atomic, strong, readonly) NSMutableArray *logObservers;

@property (atomic, assign) Class internalLogMessageClass;
@property (atomic, weak) ARKLogStore *weakDefaultLogStore;

// This ivar must be accessed directly.
@property dispatch_once_t defaultLogStoreAccessOnceToken;

@end


@implementation ARKLogDistributor

@dynamic defaultLogStore;
@synthesize defaultLogStoreAccessOnceToken = _defaultLogStoreAccessOnceToken;

#pragma mark - Class Methods

+ (instancetype)defaultDistributor;
{
    static ARKLogDistributor *ARKDefaultLogDistributor = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKDefaultLogDistributor = [[self class] new];
    });
    
    return ARKDefaultLogDistributor;
}

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logDistributingQueue = [NSOperationQueue new];
    _logDistributingQueue.name = [NSString stringWithFormat:@"%@ Log Distributing Queue", self];
    _logDistributingQueue.maxConcurrentOperationCount = 1;

#ifdef __IPHONE_8_0
    if ([_logDistributingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _logDistributingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _logObservers = [NSMutableArray new];
    
    // Use setters on public properties to ensure consistency.
    self.logMessageClass = [ARKLogMessage class];
    
    return self;
}

#pragma mark - Public Properties

- (ARKLogStore *)defaultLogStore;
{
    dispatch_once(&_defaultLogStoreAccessOnceToken, ^{
        // Lazily create a default log store if none exists.
        if (self.weakDefaultLogStore == nil) {
            self.defaultLogStore = [ARKLogStore new];
        }
    });
    
    return self.weakDefaultLogStore;
}

- (void)setDefaultLogStore:(ARKLogStore *)logStore;
{
    // Remove the old log store.
    [self removeLogObserver:self.weakDefaultLogStore];
    
    if (logStore) {
        // Add the new log store. The logObserver array will hold onto the log store strongly.
        [self addLogObserver:logStore];
    }
    
    // Store the log store weakly.
    self.weakDefaultLogStore = logStore;
}

- (Class)logMessageClass;
{
    return self.internalLogMessageClass;
}

- (void)setLogMessageClass:(Class)logMessageClass;
{
    ARKCheckCondition([logMessageClass isSubclassOfClass:[ARKLogMessage class]], , @"Attempting to set a logMessageClass that is not a subclass of ARKLogMessage!");
    
    self.internalLogMessageClass = logMessageClass;
}

#pragma mark - Private Properties

- (dispatch_once_t)defaultLogStoreAccessOnceToken;
{
    ARKCheckCondition(NO, 0, @"Should not attempt to access this token via a getter. This property must be used directly.");
}

- (void)setDefaultLogStoreAccessOnceToken:(dispatch_once_t)defaultLogStoreAccessOnceToken;
{
    ARKCheckCondition(NO, , @"Should not attempt to set this token via the setter. This property must be used directly.");
}

#pragma mark - Public Methods - Log Observers

- (void)addLogObserver:(id <ARKLogObserver>)logObserver;
{
    ARKCheckCondition(!logObserver.logDistributor || logObserver.logDistributor == self, , @"Log observer already has a distributor");
    
    logObserver.logDistributor = self;
    @synchronized(self) {
        if (![self.logObservers containsObject:logObserver]) {
            [self.logObservers addObject:logObserver];
        }
    }
}

- (void)removeLogObserver:(id <ARKLogObserver>)logObserver;
{
    logObserver.logDistributor = nil;
    @synchronized(self) {
        [self.logObservers removeObject:logObserver];
    }
}

- (void)distributeAllPendingLogsWithCompletionHandler:(dispatch_block_t)completionHandler;
{
    ARKCheckCondition(completionHandler != NULL, , @"Must provide a completion handler!");
    
    [self.logDistributingQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:completionHandler];
    }];
}

#pragma mark - Public Methods - Appending Logs

- (void)logMessage:(ARKLogMessage *)logMessage;
{
    [self.logDistributingQueue addOperationWithBlock:^{
        [self _logMessage_inLogDistributingQueue:logMessage];
    }];
}

- (void)logWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;
{
    Class logMessageClass = self.logMessageClass;
    
    [self.logDistributingQueue addOperationWithBlock:^{
        ARKLogMessage *logMessage = [[logMessageClass alloc] initWithText:text image:image type:type userInfo:userInfo];
        
        [self _logMessage_inLogDistributingQueue:logMessage];
    }];
}

- (void)logWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format arguments:(va_list)argList;
{
    NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
    [self logWithText:logText image:nil type:type userInfo:userInfo];
}

- (void)logWithType:(ARKLogType)type userInfo:(NSDictionary *)userInfo format:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self logWithType:type userInfo:userInfo format:format arguments:argList];
    va_end(argList);
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;
{
    NSString *logText = [[NSString alloc] initWithFormat:format arguments:argList];
    [self logWithText:logText image:nil type:ARKLogTypeDefault userInfo:nil];
}

- (void)logWithFormat:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList, format);
    [self logWithFormat:format arguments:argList];
    va_end(argList);
}

- (void)logScreenshot;
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 0.0);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSString *logText = @"⎙ Screenshot!";
    [self logWithText:logText image:screenshot type:ARKLogTypeDefault userInfo:nil];
}

#pragma mark - Private Methods

- (void)_logMessage_inLogDistributingQueue:(ARKLogMessage *)logMessage;
{
    NSArray *logObservers = nil;
    @synchronized(self) {
        logObservers = [self.logObservers copy];
    }
    
    for (id <ARKLogObserver> logObserver in logObservers) {
        [logObserver observeLogMessage:logMessage];
    }
}

- (void)_flushLogDistributingQueue:(NSNotification *)notification;
{
    [self.logDistributingQueue waitUntilAllOperationsAreFinished];
}

@end
