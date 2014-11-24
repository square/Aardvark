//
//  ARKLogDistributorTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"
#import "ARKLogMessage.h"
#import "ARKLogObserver.h"
#import "ARKLogStore.h"


@interface ARKLogDistributorTests : XCTestCase

@property (nonatomic, weak, readwrite) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic, weak, readwrite) ARKLogStore *logStore;

@end


typedef void (^LogHandlingBlock)(ARKLogMessage *logMessage);


@interface ARKTestLogObserver : NSObject <ARKLogObserver>

@property (nonatomic, copy, readwrite) NSMutableArray *observedLogs;

@end


@implementation ARKTestLogObserver

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _observedLogs = [NSMutableArray new];
    
    return self;
}

- (void)observeLogMessage:(ARKLogMessage *)logMessage;
{
    [self.observedLogs addObject:logMessage];
}

@end


@interface ARKLogMessageTestSubclass : ARKLogMessage
@end

@implementation ARKLogMessageTestSubclass
@end


@implementation ARKLogDistributorTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"ARKLogDistributorTests.data"];
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    
    self.logStore = logStore;
}

- (void)tearDown;
{
    [self.logStore clearLogs];
    
    // Wait for logs to be cleared.
    (void)[self.logStore allLogMessages];
    
    // Remove the default store.
    [ARKLogDistributor defaultDistributor].defaultLogStore = nil;
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_logMessageClass_defaultsToARKLogMessage;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    [logDistributor addLogObserver:self.logStore];
    
    [logDistributor logWithFormat:@"This log should be an ARKLogMessage"];
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.logStore.allLogMessages.count, 1);
    XCTAssertEqual([self.logStore.allLogMessages.firstObject class], [ARKLogMessage class]);
}

- (void)test_setLogMessageClass_appendedLogsAreCorrectClass;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    [logDistributor addLogObserver:self.logStore];
    
    logDistributor.logMessageClass = [ARKLogMessageTestSubclass class];
    [logDistributor logWithFormat:@"This log should be an ARKLogMessageTestSubclass"];
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.logStore.allLogMessages.count, 1);
    XCTAssertEqual([self.logStore.allLogMessages.firstObject class], [ARKLogMessageTestSubclass class]);
}

- (void)test_addLogObserver_notifiesLogObserverOnARKLog;
{
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    [self.defaultLogDistributor addLogObserver:testLogObserver];
    
    XCTAssertEqual(testLogObserver.observedLogs.count, 0);
    
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    XCTAssertGreaterThan(self.logStore.allLogMessages.count, 0);
    [self.logStore.allLogMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(logMessage, testLogObserver.observedLogs[idx]);
    }];
    
    [self.defaultLogDistributor removeLogObserver:testLogObserver];
}

- (void)test_addLogObserver_notifiesLogObserverOnLogWithFormat;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    [logDistributor addLogObserver:testLogObserver];
    
    [logDistributor logWithFormat:@"Log"];
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(testLogObserver.observedLogs.count, 1);
}

- (void)test_removeLogObserver_removesLogObserver;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    
    [logDistributor addLogObserver:testLogObserver];
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(logDistributor.logObservers.count, 1);
    
    [logDistributor removeLogObserver:testLogObserver];
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(logDistributor.logObservers.count, 0);
    
    for (NSUInteger i  = 0; i < 100; i++) {
        [logDistributor logWithFormat:@"Log %@", @(i)];
    }
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(testLogObserver.observedLogs.count, 0);
}

- (void)test_flushLogDistributingQueue_informsLogObserversOfAllPendingLogs;
{
    NSMutableSet *numbers = [NSMutableSet new];
    for (NSUInteger i  = 0; i < 100; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, BOOL *stop) {
        // Log to ARKLog, which will cause the default log distributor to queue up observeLogMessage: calls on its log observers on its background queue.
        ARKLog(@"%@", text);
    }];
    
    // Calling allLogMessges on the logStore will cause the logStore to fire ARKLogObserverRequiresAllPendingLogsNotification. This will call _flushLogDistributingQueue:, which will cause the queued observeLogMessage: calls to be executed. This will result in the logStore returing all logs that have been enqueued to date.
    NSArray *allLogMessages = self.logStore.allLogMessages;
    
    // Internal log queue should now be empty.
    XCTAssertEqual(self.defaultLogDistributor.logDistributingQueue.operationCount, 0);
    
    NSMutableSet *allLogText = [NSMutableSet new];
    for (ARKLogMessage *logMessage in allLogMessages) {
        [allLogText addObject:logMessage.text];
    }
    
    // allLogText should contain the same content as the original log set.
    XCTAssertEqualObjects(allLogText, numbers);
}

@end
