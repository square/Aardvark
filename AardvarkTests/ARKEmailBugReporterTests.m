//
//  ARKEmailBugReporterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/20/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReporter_Testing.h"

#import "ARKLogDistributor.h"
#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"


@interface ARKEmailBugReporterTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic, strong, readwrite) ARKEmailBugReporter *bugReporter;
@property (nonatomic, weak, readwrite) ARKLogStore *logStore;

@end


@implementation ARKEmailBugReporterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    self.bugReporter = [ARKEmailBugReporter new];
    
    ARKLogStore *logStore = [ARKLogStore new];
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    self.logStore = logStore;
}

- (void)tearDown;
{
    [ARKLogDistributor defaultDistributor].defaultLogStore = nil;
    
    [self.logStore clearLogs];
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    [super tearDown];
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
    
    const NSUInteger numberOfRecentErrorLogs = 5;
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
    const NSUInteger numberOfRecentErrorLogs = 5;
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        __block NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
        
        XCTAssertEqualObjects(recentErrorLogs, nil);
        
        ARKLog(@"This is not an error");
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
            
            XCTAssertEqualObjects(recentErrorLogs, nil);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfRecentErrorLogsIsZero;
{
    const NSUInteger numberOfRecentErrorLogs = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        __block NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
        
        XCTAssertEqualObjects(recentErrorLogs, nil);
        
        ARKLog(@"This is not an error");
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:logMessages count:numberOfRecentErrorLogs];
            
            XCTAssertEqualObjects(recentErrorLogs, nil);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_addLogStores_enforcesARKLogStoreClass;
{
    XCTAssertThrows([self.bugReporter addLogStores:@[[NSObject new]]]);
}

- (void)test_removeLogStores_enforcesARKLogStoreClass;
{
    XCTAssertThrows([self.bugReporter removeLogStores:@[[NSObject new]]]);
}

@end
