//
//  ARKLogDistributor.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
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

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"

#import "AardvarkDefines.h"
#import "ARKLogMessage.h"
#import "ARKLogObserver.h"
#import "ARKLogStore.h"


@interface ARKLogDistributor ()

@property (nonatomic, strong, readonly) NSOperationQueue *logDistributingQueue;
@property (atomic, strong, readonly) NSMutableArray *logObservers;

@property (atomic, assign) Class internalLogMessageClass;
@property (atomic, weak) ARKLogStore *weakDefaultLogStore;
@property (atomic, strong, readonly) NSRecursiveLock *defaultLogStorePropertyLock;


/// Set to YES after calling `defaultLogStore`.
/// Ensures that we only lazily create the default log store if `defaultLogStore` is nil the very first time it is called,
/// and never after that.
@property BOOL defaultLogStoreAccessorCalled;

@end


@implementation ARKLogDistributor

@dynamic defaultLogStore;

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

    _defaultLogStorePropertyLock = [NSRecursiveLock new];
    _defaultLogStorePropertyLock.name = @"Default Log Store Property Lock";
    
    // Use setters on public properties to ensure consistency.
    self.logMessageClass = [ARKLogMessage class];
    
    return self;
}

#pragma mark - Public Properties

- (ARKLogStore *)defaultLogStore;
{
    /**
    * Ensure that changes to self.defaultLogStoreAccessorCalled and self.defaultLogStore (via self.weakDefaultLogStore)
    * are mututally exclusive.
    */
    [self.defaultLogStorePropertyLock lock];
    {
        if (!self.defaultLogStoreAccessorCalled && self.weakDefaultLogStore == nil) {
            // Lazily create a default log store if none exists.
            ARKLogStore *defaultLogStore = [[ARKLogStore alloc] initWithPersistedLogFileName:[NSStringFromClass([self class]) stringByAppendingString:@"_DefaultLogStore"]];
            defaultLogStore.name = @"Default";
            defaultLogStore.prefixNameWhenPrintingToConsole = NO;
            self.defaultLogStore = defaultLogStore;
        }

        self.defaultLogStoreAccessorCalled = YES;
    }
    [self.defaultLogStorePropertyLock unlock];
    
    return self.weakDefaultLogStore;
}

- (void)setDefaultLogStore:(ARKLogStore *)logStore;
{
    [self.defaultLogStorePropertyLock lock];
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
    [self.defaultLogStorePropertyLock unlock];
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

- (NSSet *)logStores;
{
    NSSet *logObservers = nil;

    @synchronized (self) {
        logObservers = [self.logObservers copy];
    }

    NSMutableSet *logStores = [NSMutableSet new];
    for (id <ARKLogObserver> logObserver in logObservers) {
        if ([logObserver isKindOfClass:[ARKLogStore class]]) {
            [logStores addObject:logObserver];
        }
    }

    return [logStores copy];
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
    
    NSString *logText = @"Screenshot Logged";
    [self logWithText:logText image:screenshot type:ARKLogTypeScreenshot userInfo:nil];
}

#pragma mark - Protected Methods

- (void)waitUntilAllPendingLogsHaveBeenDistributed;
{
    [self.logDistributingQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Testing Methods

- (NSUInteger)internalQueueOperationCount;
{
    return self.logDistributingQueue.operationCount;
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

@end
