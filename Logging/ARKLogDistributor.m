//
//  ARKLogDistributor.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"

#import "ARKLogConsumer.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"
#import "NSOperationQueue+ARKAdditions.h"


@interface ARKLogDistributor ()

@property (nonatomic, strong, readonly) NSOperationQueue *logAppendingQueue;
@property (nonatomic, strong, readonly) NSMutableArray *logConsumers;

@end


@implementation ARKLogDistributor

@synthesize logMessageClass = _logMessageClass;
@synthesize logConsumers = _logConsumers;

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

static __weak ARKLogStore *defaultLogStore;

+ (void)setDefaultLogStore:(ARKLogStore *)logStore;
{
    // Remove the old log store.
    [[self defaultDistributor] removeLogConsumer:defaultLogStore];
    
    // Store the log store weakly.
    defaultLogStore = logStore;
    
    if (logStore != nil) {
        // Add the new log store. The default distributor will hold onto the log store strongly.
        [[self defaultDistributor] addLogConsumer:logStore];
    }
}

+ (ARKLogStore *)defaultLogStore;
{
    return defaultLogStore;
}

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logAppendingQueue = [NSOperationQueue new];
    _logAppendingQueue.maxConcurrentOperationCount = 1;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 /* __IPHONE_8_0 */
    if ([_logAppendingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _logAppendingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _logConsumers = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_flushLogAppendingQueue:) name:ARKLogConsumerRequiresAllPendingLogsNotification object:nil];
    
    // Use setters on public properties to ensure consistency.
    self.logMessageClass = [ARKLogMessage class];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (Class)logMessageClass;
{
    if ([NSOperationQueue currentQueue] == self.logAppendingQueue) {
        return _logMessageClass;
    } else {
        __block Class logMessageClass = NULL;
        
        [self.logAppendingQueue performOperationWithBlock:^{
            logMessageClass = _logMessageClass;
        } waitUntilFinished:YES];
        
        return logMessageClass;
    }
}

- (void)setLogMessageClass:(Class)logMessageClass;
{
    NSAssert([logMessageClass isSubclassOfClass:[ARKLogMessage class]], @"Attempting to set a logMessageClass that is not a subclass of ARKLogMessage!");
    
    [self.logAppendingQueue addOperationWithBlock:^{
        if (_logMessageClass == logMessageClass) {
            return;
        }
        
        _logMessageClass = logMessageClass;
    }];
}

- (NSMutableArray *)logConsumers;
{
    if ([NSOperationQueue currentQueue] == self.logAppendingQueue) {
        return _logConsumers;
    } else {
        __block NSMutableArray *logConsumers = NULL;
        
        [self.logAppendingQueue performOperationWithBlock:^{
            logConsumers = _logConsumers;
        } waitUntilFinished:YES];
        
        return logConsumers;
    }
}

#pragma mark - Public Methods - Log Handlers

- (void)addLogConsumer:(id <ARKLogConsumer>)logConsumer;
{
    NSAssert([logConsumer conformsToProtocol:@protocol(ARKLogConsumer)], @"Tried to add a log handler that does not conform to ARKLogDistributor protocol");
    
    [self.logAppendingQueue addOperationWithBlock:^{
        if (![self.logConsumers containsObject:logConsumer]) {
            [self.logConsumers addObject:logConsumer];
        }
    }];
}

- (void)removeLogConsumer:(id <ARKLogConsumer>)logConsumer;
{
    [self.logAppendingQueue addOperationWithBlock:^{
        [self.logConsumers removeObject:logConsumer];
    }];
}

#pragma mark - Public Methods - Appending Logs

- (void)logMessage:(ARKLogMessage *)logMessage;
{
    [self.logAppendingQueue addOperationWithBlock:^{
        [self _logMessage_inLogAppendingQueue:logMessage];
    }];
}

- (void)logWithText:(NSString *)text image:(UIImage *)image type:(ARKLogType)type userInfo:(NSDictionary *)userInfo;
{
    [self.logAppendingQueue addOperationWithBlock:^{
        ARKLogMessage *logMessage = [[self.logMessageClass alloc] initWithText:text image:image type:type userInfo:userInfo];
        
        [self _logMessage_inLogAppendingQueue:logMessage];
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
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSString *logText = @"📷📱 Screenshot!";
    [self logWithText:logText image:screenshot type:ARKLogTypeDefault userInfo:nil];
}

#pragma mark - Private Methods

- (void)_logMessage_inLogAppendingQueue:(ARKLogMessage *)logMessage;
{
    for (id <ARKLogConsumer> logConsumer in self.logConsumers) {
        [logConsumer consumeLogMessage:logMessage];
    }
}

- (void)_flushLogAppendingQueue:(NSNotification *)notification;
{
    if ([self.logConsumers containsObject:notification.object]) {
        [self.logAppendingQueue waitUntilAllOperationsAreFinished];
    }
}

@end
