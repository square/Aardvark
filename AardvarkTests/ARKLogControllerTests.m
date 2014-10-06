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
@end


@implementation ARKLogControllerTests

#pragma mark - Setup

- (void)tearDown;
{
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    [super tearDown];
}

#pragma mark - Test Behavior

- (void)testLogEntry
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
    NSUInteger numberOfLogsToEnter = 2 * logController.maximumLogCount + 10;
    NSUInteger expectedInternalLogCount = logController.maximumLogCount + (numberOfLogsToEnter % logController.maximumLogCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + logController.maximumLogCount); i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    // Wait until all logs are entered.
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(logController.logs.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(logController.maximumLogCount), @(expectedInternalLogCount), @(logController.logs.count));
    
    // Exposed log count should never be greater than maximumLogCount.
    NSArray *allLogs = logController.allLogs;
    XCTAssertGreaterThanOrEqual(allLogs.count, logController.maximumLogCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(allLogs.count), @(logController.maximumLogCount));
}

- (void)testClearLogs;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < [ARKLogController sharedInstance].maximumLogCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    XCTAssertTrue([ARKLogController sharedInstance].allLogs.count == 0, @"Local logs have count of %@ after clearing!", @([ARKLogController sharedInstance].allLogs.count));
}

- (void)testPersistLogs;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = logController.maximumLogCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    
    NSArray *logsToPerist = [logController _trimedLogsToPersist_inLoggingQueue];
    XCTAssertEqual(logsToPerist.count, logController.maximumLogCountToPersist);
    
    [logController _persistLogs_inLoggingQueue];
    XCTAssertEqual(logController.logs.count, numberOfLogsToEnter, @"Persisting logs should not have affected internal log count");
}

#pragma mark - Test Performance

- (void)testLogEntryPerformance;
{
    ARKLogController *logController = [ARKLogController sharedInstance];

    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)testLogEntryAndRetreivalPerformance;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        // Trim and format the logs.
        (void)logController.allLogs;
    }];
}
- (void)testTruncationPerformance;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [logController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [logController _trimLogs_inLoggingQueue];
        }];
        
        [logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)testLogPersistencePerformance;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        [logController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [logController _persistLogs_inLoggingQueue];
        }];
        
        [logController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

@end
