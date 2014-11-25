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
#import "ARKLogStore_Testing.h"


@interface ARKLogDistributorTests : XCTestCase

@property (nonatomic, weak, readwrite) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic, weak, readwrite) ARKLogStore *defaultLogStore;

@end


typedef void (^LogHandlingBlock)(ARKLogMessage *logMessage);


@interface ARKTestLogObserver : NSObject <ARKLogObserver>

@property (nonatomic, copy, readwrite) NSMutableArray *observedLogs;

@end


@implementation ARKTestLogObserver

@synthesize logDistributor;

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
    
    self.defaultLogStore = logStore;
}

- (void)tearDown;
{
    [ARKLogDistributor defaultDistributor].defaultLogStore = nil;
    
    [self.defaultLogStore clearLogs];
    [self.defaultLogStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_logMessageClass_defaultsToARKLogMessage;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    ARKLogStore *logStore = [ARKLogStore new];
    [logDistributor addLogObserver:logStore];
    
    [logDistributor logWithFormat:@"This log should be an ARKLogMessage"];
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(logStore.logMessages.count, 1);
    XCTAssertEqual([logStore.logMessages.firstObject class], [ARKLogMessage class]);
}

- (void)test_setLogMessageClass_appendedLogsAreCorrectClass;
{
    ARKLogStore *logStore = [ARKLogStore new];
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    [logDistributor addLogObserver:logStore];
    
    logDistributor.logMessageClass = [ARKLogMessageTestSubclass class];
    [logDistributor logWithFormat:@"This log should be an ARKLogMessageTestSubclass"];
    
    [logDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(logStore.logMessages.count, 1);
    XCTAssertEqual([logStore.logMessages.firstObject class], [ARKLogMessageTestSubclass class]);
}

- (void)test_addLogObserver_notifiesLogObserverOnARKLog;
{
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    [self.defaultLogDistributor addLogObserver:testLogObserver];
    
    XCTAssertEqual(testLogObserver.observedLogs.count, 0);
    
    for (NSUInteger i  = 0; i < self.defaultLogStore.maximumLogMessageCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogDistributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    [self.defaultLogStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(self.defaultLogStore.logMessages.count, self.defaultLogStore.maximumLogMessageCount);
    [self.defaultLogStore.logMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
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

- (void)test_distributeAllPendingLogsWithCompletionHandler_informsLogObserversOfAllPendingLogs;
{
    NSMutableSet *numbers = [NSMutableSet new];
    for (NSUInteger i  = 0; i < 100; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, BOOL *stop) {
        // Log to ARKLog, which will cause the default log distributor to queue up observeLogMessage: calls on its log observers on its background queue.
        ARKLog(@"%@", text);
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_distributeAllPendingLogsWithCompletionHandler_informsLogObserversOfAllPendingLogs"];
    [self.defaultLogDistributor distributeAllPendingLogsWithCompletionHandler:^{
        // Internal log queue should now be empty.
        XCTAssertEqual(self.defaultLogDistributor.logDistributingQueue.operationCount, 0);
        
        [self.defaultLogStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            NSMutableSet *allLogText = [NSMutableSet new];
            for (ARKLogMessage *logMessage in logMessages) {
                [allLogText addObject:logMessage.text];
            }
            
            // allLogText should contain the same content as the original log set.
            XCTAssertEqualObjects(allLogText, numbers);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Performance Tests

- (void)test_logDistribution_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.defaultLogStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.defaultLogDistributor logWithFormat:@"%@", text];
        }];
    }];
}

@end
