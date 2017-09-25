//
//  ARKEmailBugReporterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/20/14.
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

#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReporter_Testing.h"

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"
#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"
#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"


@interface ARKEmailBugReporterTests : XCTestCase

@property (nonatomic) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic) ARKEmailBugReporter *bugReporter;
@property (nonatomic, weak) ARKLogStore *logStore;

@end


@implementation ARKEmailBugReporterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromClass([self class])];
    
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    self.logStore = logStore;
    
    self.bugReporter = [[ARKEmailBugReporter alloc] initWithEmailAddress:@"ARKEmailBugReporterTests@squareup.com" logStore:logStore];
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Behavior Tests

- (void)test_recentErrorLogMessagesAsPlainText_countRespected;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLogWithType(ARKLogTypeError, nil, @"%@", number);
    }];
    
    NSUInteger const numberOfRecentErrorLogs = 5;
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
        XCTAssertEqual([recentErrorLogs componentsSeparatedByString:@"\n"].count, numberOfRecentErrorLogs);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfNoErrorLogsPresent;
{
    NSUInteger const numberOfRecentErrorLogs = 5;
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        __block NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
        
        XCTAssertEqualObjects(recentErrorLogs, @"");
        
        ARKLog(@"This is not an error");
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
            
            XCTAssertEqualObjects(recentErrorLogs, @"");
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfRecentErrorLogsIsZero;
{
    NSUInteger const numberOfRecentErrorLogs = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        __block NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
        
        XCTAssertEqualObjects(recentErrorLogs, @"");
        
        ARKLog(@"This is not an error");
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
            
            XCTAssertEqualObjects(recentErrorLogs, @"");
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_addLogStores_enforcesARKLogStoreClass;
{
    XCTAssertEqualObjects(self.bugReporter.logStores, @[self.logStore]);
    
    [self.bugReporter addLogStores:@[(ARKLogStore *)[NSObject new]]];
    
    XCTAssertEqualObjects(self.bugReporter.logStores, @[self.logStore]);
}

@end
