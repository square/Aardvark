//
//  ARKLogStoreTests.m
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
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

#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"
#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"
#import "ARKLogMessage.h"


@interface ARKLogStoreTests : XCTestCase

@property (nonatomic, weak) ARKLogStore *logStore;
@property (nonatomic) ARKLogDistributor *logDistributor;

@end


@implementation ARKLogStoreTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromClass([self class])];

    self.logDistributor = [ARKLogDistributor new];
    [self.logDistributor addLogObserver:logStore];
    
    self.logStore = logStore;
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)tearDown;
{
    ARKLogStore *const logStoreToRemove = self.logStore;
    if (logStoreToRemove != nil) {
        [self.logDistributor removeLogObserver:logStoreToRemove];
    }
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_observeLogMessage_logsLogToLogStore;
{
    [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Logging Enabled" image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1, @"Log not stored!");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_observeLogMessage_trimsOldestLogs;
{
    NSString *lastLogText = nil;
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount + 1; i++) {
        lastLogText = [NSString stringWithFormat:@"Log %@", @(i)];
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:lastLogText image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        ARKLogMessage *lastLog = logMessages.lastObject;
        XCTAssertEqualObjects(lastLog.text, lastLogText);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_logFilterBlock_preventsLogsFromBeingObserved;
{
    NSString *const ARKLogStoreTestShouldLogKey = @"ARKLogStoreTestShouldLog";
    
    self.logStore.logFilterBlock = ^(ARKLogMessage *logMessage) {
        return [logMessage.userInfo[ARKLogStoreTestShouldLogKey] boolValue];
    };
    
    NSDictionary *userInfo = @{ ARKLogStoreTestShouldLogKey : @NO };
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault parameters:@{} userInfo:userInfo]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 0);
        
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Log This Log" image:nil type:ARKLogTypeDefault parameters:@{} userInfo:@{ ARKLogStoreTestShouldLogKey : @YES }]];
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            XCTAssertEqual(logMessages.count, 1);
            
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Do Not Log This Log" image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
            
            [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
                XCTAssertEqual(logMessages.count, 1);
                
                [expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_retrieveAllLogMessagesWithCompletionHandler_capturesAllLogsLogged;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently log to the default log distributor.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logDistributor logWithFormat:@"%@", text];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, numbers.count);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_retrieveAllLogMessagesWithCompletionHandler_callsCompletionHandlerIfNoLogDistributor;
{
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromSelector(_cmd)];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertNil(logMessages);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_retrieveAllLogMessagesWithCompletionHandler_completionHandlerCalledOnMainQueue;
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_clearLogsWithCompletionHandler_removesAllLogMessages;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore clearLogsWithCompletionHandler:^{
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            XCTAssertTrue(logMessages.count == 0, @"Local logs have count of %@ after clearing!", @(logMessages.count));
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_waitUntilAllOperationsAreFinished_completionHandlerCalledOnMainQueue;
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore clearLogsWithCompletionHandler:^{
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Performance Tests

- (void)test_observeLogMessage_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
        }];
        
        [self.logStore.dataArchive waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_observeLogMessageAndTrim_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
        }];
        
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"straw that broke the camel's back" image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
        
        [self.logStore.dataArchive clearArchiveWithCompletionHandler:NULL];
        [self.logStore.dataArchive waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_retrieveAllLogMessagesWithCompletionHandler_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }];
    
    [self measureBlock:^{
        XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
    }];
}

- (void)test_persistLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }];
    
    [self measureBlock:^{
        [self.logStore.dataArchive saveArchiveAndWait:YES];
    }];
}

- (void)test_persistLogsAndSave_performance;
{
    NSMutableArray *logMessages = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [logMessages addObject:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [logMessages enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
            [self.logStore observeLogMessage:logMessage];
        }];
        
        [self.logStore.dataArchive saveArchiveAndWait:YES];
    }];
}

- (void)test_loadPersistedLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }];
    
    // Persist the logs.
    [self.logStore.dataArchive saveArchiveAndWait:YES];
    
    [self measureBlock:^{
        NSURL *const archiveFileURL = self.logStore.dataArchive.archiveFileURL;
        if (archiveFileURL != nil) {
            ARKDataArchive *const loadingDataArchive = [[ARKDataArchive alloc] initWithURL:archiveFileURL maximumObjectCount:self.logStore.dataArchive.maximumObjectCount trimmedObjectCount:self.logStore.dataArchive.trimmedObjectCount];
            [loadingDataArchive waitUntilAllOperationsAreFinished];
        }
    }];
}

@end
