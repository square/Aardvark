//
//  ARKLogDistributorTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
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

@import XCTest;

#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Protected.h"
#import "ARKLogDistributor_Testing.h"

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"
#import "ARKLogMessage.h"
#import "ARKLogObserver.h"
#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"


@interface ARKLogDistributorTests : XCTestCase

@property (nonatomic, strong) ARKLogDistributor *logDistributor;
@property (nonatomic, weak) ARKLogStore *logStore;

@end


@interface ARKTestLogObserver : NSObject <ARKLogObserver>

@property (nonatomic, copy) NSMutableArray *observedLogs;

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
    
    self.logDistributor = [ARKLogDistributor new];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromClass([self class])];
    
    self.logDistributor.defaultLogStore = logStore;
    self.logStore = logStore;
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)tearDown;
{
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    self.logDistributor.logMessageClass = [ARKLogMessage class];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_logMessageClass_defaultsToARKLogMessage;
{
    [self.logDistributor logWithFormat:@"This log should be an ARKLogMessage"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        XCTAssertEqual([logMessages.firstObject class], [ARKLogMessage class]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_setLogMessageClass_appendedLogsAreCorrectClass;
{
    self.logDistributor.logMessageClass = [ARKLogMessageTestSubclass class];
    [self.logDistributor logWithFormat:@"This log should be an ARKLogMessageTestSubclass"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        XCTAssertEqual([logMessages.firstObject class], [ARKLogMessageTestSubclass class]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_defaultLogStore_lazilyInitializesOnFirstAccess;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    ARKLogStore *defaultLogStore = logDistributor.defaultLogStore;
    XCTAssertNotNil(defaultLogStore);
    XCTAssertEqualObjects(defaultLogStore.name, @"Default");
    XCTAssertFalse(defaultLogStore.prefixNameWhenPrintingToConsole);

    // Should return the same instance on subsequent property accesses.
    XCTAssertEqual(logDistributor.defaultLogStore, defaultLogStore);
}

- (void)test_addLogObserver_notifiesLogObserverOnLogWithFormat;
{
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    [self.logDistributor addLogObserver:testLogObserver];
    
    XCTAssertEqual(testLogObserver.observedLogs.count, 0);
    
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logDistributor logWithFormat:@"Log %@", @(i)];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, self.logStore.maximumLogMessageCount);
        [logMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
            XCTAssertEqualObjects(logMessage, testLogObserver.observedLogs[idx]);
        }];
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    [self.logDistributor removeLogObserver:testLogObserver];
}

- (void)test_removeLogObserver_removesLogObserver;
{
    ARKLogDistributor *logDistributor = [ARKLogDistributor new];
    ARKTestLogObserver *testLogObserver = [ARKTestLogObserver new];
    
    [logDistributor addLogObserver:testLogObserver];
    
    XCTAssertEqual(logDistributor.logObservers.count, 1);
    
    [logDistributor removeLogObserver:testLogObserver];
    
    XCTAssertEqual(logDistributor.logObservers.count, 0);
    
    for (NSUInteger i  = 0; i < 100; i++) {
        [logDistributor logWithFormat:@"Log %@", @(i)];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logDistributor distributeAllPendingLogsWithCompletionHandler:^{
        XCTAssertEqual(testLogObserver.observedLogs.count, 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_distributeAllPendingLogsWithCompletionHandler_informsLogObserversOfAllPendingLogs;
{
    NSMutableSet *numbers = [NSMutableSet new];
    for (NSUInteger i  = 0; i < 100; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, BOOL *stop) {
        // Log to ARKLog, which will cause the log distributor to queue up observeLogMessage: calls on its log observers on its background queue.
        [self.logDistributor logWithFormat:@"%@", text];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
        // Internal log queue should now be empty.
        XCTAssertEqual(self.logDistributor.internalQueueOperationCount, 0);
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
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
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logDistributor logWithFormat:@"%@", text];
        }];
        
        // Make sure that the logs are fully distributed within the measureBlock:
        XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
        [self.logDistributor distributeAllPendingLogsWithCompletionHandler:^{
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
    }];
}

@end
