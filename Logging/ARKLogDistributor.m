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

@property (nonatomic, strong, readonly) NSOperationQueue *logDistributingQueue;
@property (nonatomic, strong, readonly) NSMutableArray *logConsumers;

@property (nonatomic, weak, readwrite) ARKLogStore *weakDefaultLogStore;

@end


@implementation ARKLogDistributor

@dynamic defaultLogStore;
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

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logDistributingQueue = [NSOperationQueue new];
    _logDistributingQueue.maxConcurrentOperationCount = 1;

#ifdef __IPHONE_8_0
    if ([_logDistributingQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _logDistributingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    _logConsumers = [NSMutableArray new];
    
    // Use setters on public properties to ensure consistency.
    self.logMessageClass = [ARKLogMessage class];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (ARKLogStore *)defaultLogStore;
{
    if ([NSOperationQueue currentQueue] == self.logDistributingQueue) {
        return _weakDefaultLogStore;
    } else {
        __block ARKLogStore *defaultLogStore = nil;
        
        [self.logDistributingQueue performOperationWithBlock:^{
            defaultLogStore = _weakDefaultLogStore;
        } waitUntilFinished:YES];
        
        return _weakDefaultLogStore;
    }
}

- (void)setDefaultLogStore:(ARKLogStore *)logStore;
{
    // Remove the old log store.
    [self removeLogConsumer:_weakDefaultLogStore];
    
    if (logStore) {
        // Add the new log store. The logConsumer array will hold onto the log store strongly.
        [self addLogConsumer:logStore];
    }
    
    [self.logDistributingQueue addOperationWithBlock:^{
        // Store the log store weakly.
        _weakDefaultLogStore = logStore;
    }];
}

- (Class)logMessageClass;
{
    if ([NSOperationQueue currentQueue] == self.logDistributingQueue) {
        return _logMessageClass;
    } else {
        __block Class logMessageClass = NULL;
        
        [self.logDistributingQueue performOperationWithBlock:^{
            logMessageClass = _logMessageClass;
        } waitUntilFinished:YES];
        
        return logMessageClass;
    }
}

- (void)setLogMessageClass:(Class)logMessageClass;
{
    NSAssert([logMessageClass isSubclassOfClass:[ARKLogMessage class]], @"Attempting to set a logMessageClass that is not a subclass of ARKLogMessage!");
    
    [self.logDistributingQueue addOperationWithBlock:^{
        if (_logMessageClass == logMessageClass) {
            return;
        }
        
        _logMessageClass = logMessageClass;
    }];
}

#pragma mark - Public Methods - Log Handlers

- (void)addLogConsumer:(id <ARKLogConsumer>)logConsumer;
{
    NSAssert([logConsumer conformsToProtocol:@protocol(ARKLogConsumer)], @"Tried to add a log handler that does not conform to ARKLogDistributor protocol");
    
    [self.logDistributingQueue performOperationWithBlock:^{
        if (![self.logConsumers containsObject:logConsumer]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_flushLogDistributingQueue:) name:ARKLogConsumerRequiresAllPendingLogsNotification object:logConsumer];
            [self.logConsumers addObject:logConsumer];
        }
    } waitUntilFinished:YES];
}

- (void)removeLogConsumer:(id <ARKLogConsumer>)logConsumer;
{
    [self.logDistributingQueue performOperationWithBlock:^{
        if (logConsumer) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:ARKLogConsumerRequiresAllPendingLogsNotification object:logConsumer];
        }
        
        [self.logConsumers removeObject:logConsumer];
    } waitUntilFinished:YES];
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
    [self.logDistributingQueue addOperationWithBlock:^{
        ARKLogMessage *logMessage = [[self.logMessageClass alloc] initWithText:text image:image type:type userInfo:userInfo];
        
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
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSString *logText = @"📷📱 Screenshot!";
    [self logWithText:logText image:screenshot type:ARKLogTypeDefault userInfo:nil];
}

#pragma mark - Private Methods

- (void)_logMessage_inLogDistributingQueue:(ARKLogMessage *)logMessage;
{
    for (id <ARKLogConsumer> logConsumer in self.logConsumers) {
        [logConsumer consumeLogMessage:logMessage];
    }
}

- (void)_flushLogDistributingQueue:(NSNotification *)notification;
{
    [self.logDistributingQueue waitUntilAllOperationsAreFinished];
}

@end
