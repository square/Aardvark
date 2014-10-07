//
//  ARKLogControllerTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKLogController.h"
#import "ARKLogController_Testing.h"


@interface ARKLogControllerTests : XCTestCase

@property (nonatomic, weak, readwrite) ARKLogController *logController;

@end


@implementation ARKLogControllerTests

#pragma mark - Setup

- (void)setUp;
{
    [Aardvark enableAardvarkLogging];
    self.logController = [ARKLogController sharedInstance];
}

- (void)tearDown;
{
    [self.logController clearLogs];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_appendLog_logCountExpected;
{
    NSUInteger numberOfLogsToEnter = 2 * self.logController.maximumLogCount + 10;
    NSUInteger expectedInternalLogCount = self.logController.maximumLogCount + (numberOfLogsToEnter % self.logController.maximumLogCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + self.logController.maximumLogCount); i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    // Wait until all logs are entered.
    [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(self.logController.logs.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(self.logController.maximumLogCount), @(expectedInternalLogCount), @(self.logController.logs.count));
    
    // Exposed log count should never be greater than maximumLogCount.
    NSArray *allLogs = self.logController.allLogs;
    XCTAssertGreaterThanOrEqual(allLogs.count, self.logController.maximumLogCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(allLogs.count), @(self.logController.maximumLogCount));
}

- (void)test_clearLogs_removesAllLogs;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.logController.maximumLogCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.logController clearLogs];
    
    XCTAssertTrue(self.logController.logs.count == 0, @"Local logs have count of %@ after clearing!", @(self.logController.logs.count));
    XCTAssertTrue(self.logController.allLogs.count == 0, @"Local logs have count of %@ after clearing!", @(self.logController.allLogs.count));
}

- (void)test_clearLogs_removesPersistedLogs;
{
    XCTAssertNil([self.logController _persistedLogs]);
    
    ARKLog(@"Log");
    [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    [self.logController _persistLogs_inLoggingQueue];
    XCTAssertNotNil([self.logController _persistedLogs]);
    
    [self.logController clearLogs];
    XCTAssertNil([self.logController _persistedLogs]);
}

- (void)test_trimmedLogsToPersistLogs_maximumLogCountToPersistPersisted;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logController.maximumLogCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    
    NSArray *logsToPerist = [self.logController _trimedLogsToPersist_inLoggingQueue];
    XCTAssertEqual(logsToPerist.count, self.logController.maximumLogCountToPersist);
}

- (void)test_persistLogs_noSideEffect;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logController.maximumLogCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    
    [self.logController _persistLogs_inLoggingQueue];
    XCTAssertEqual(self.logController.logs.count, numberOfLogsToEnter, @"Persisting logs should not have affected internal log count");
}

#pragma mark - Performance Tests

- (void)test_appendLog_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_allLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        // Trim and format the logs.
        (void)self.logController.allLogs;
    }];
}
- (void)test_trimLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [self.logController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logController _trimLogs_inLoggingQueue];
        }];
        
        [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_persistLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        [self.logController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logController _persistLogs_inLoggingQueue];
        }];
        
        [self.logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

@end
