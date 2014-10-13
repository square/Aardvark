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
#import "ARKLogMessage.h"


@interface ARKLogControllerTests : XCTestCase

@property (nonatomic, weak, readwrite) ARKLogController *defaultLogController;

@end


@interface ARKLogMessageTestSubclass : ARKLogMessage
@end

@implementation ARKLogMessageTestSubclass
@end


@implementation ARKLogControllerTests

#pragma mark - Setup

- (void)setUp;
{
    [Aardvark enableDefaultLogController];
    self.defaultLogController = [ARKLogController defaultController];
}

- (void)tearDown;
{
    [self.defaultLogController clearLogs];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_initDefaultController_setsPersistencePath;
{
    XCTAssertGreaterThan(self.defaultLogController.persistedLogsFilePath.length, 0);
}

- (void)test_init_doesNotSetPersistencePath;
{
    XCTAssertEqual([ARKLogController new].persistedLogsFilePath.length, 0);
}

- (void)test_loggingEnabled_loggingInitiallyDisabled;
{
    ARKLogController *logController = [ARKLogController new];
    
    [logController appendLog:@"Logging Disabled"];
    
    XCTAssertEqual(logController.allLogMessages.count, 0, @"Log appended with logging not yet enabled!");
}

- (void)test_loggingEnabled_logsAppendedWhenLoggingEnabled;
{
    ARKLog(@"Logging Enabled");
    
    XCTAssertEqual(self.defaultLogController.allLogMessages.count, 1, @"Log not appended with logging enabled!");
}

- (void)test_loggingEnabled_logsAreNotAppendedWhenLoggingIsDisabled;
{
    XCTAssertEqual(self.defaultLogController.allLogMessages.count, 0);
    
    [Aardvark disableDefaultLogController];
    ARKLog(@"Logging Disabled");
    
    XCTAssertEqual(self.defaultLogController.allLogMessages.count, 0, @"Log appended with logging disabled!");
}

- (void)test_setLogMessageClass_onlySetOnce;
{
    ARKLogController *logController = [ARKLogController new];
    logController.logMessageClass = [ARKLogMessageTestSubclass class];
    
    XCTAssertEqual(logController.logMessageClass, [ARKLogMessageTestSubclass class], @"Setting logMessageClass failed");
    
    logController.logMessageClass = [ARKLogMessage class];
    
    XCTAssertEqual(logController.logMessageClass, [ARKLogMessageTestSubclass class], @"Setting logMessageClass a second time succeeded");
}

- (void)test_addLogBlockWithKey_logsToLogBlock;
{
    NSMutableArray *logBlockTest = [NSMutableArray new];
    
    [self.defaultLogController addLogBlock:^(NSString *text, NSDictionary *userInfo) {
        [logBlockTest addObject:text];
    } withKey:@"lobBlockTest"];
    
    XCTAssertEqual(logBlockTest.count, 0);
    
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    [self.defaultLogController.logMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(logMessage.text, logBlockTest[idx]);
    }];
    
    [self.defaultLogController removeLogBlockWithKey:@"lobBlockTest"];
}

- (void)test_removeLobBlockWithKey_removesLobBlock;
{
    NSMutableArray *logBlockTest = [NSMutableArray new];
    
    [self.defaultLogController addLogBlock:^(NSString *text, NSDictionary *userInfo) {
        [logBlockTest addObject:text];
    } withKey:@"lobBlockTest"];
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.defaultLogController.logBlocks.allValues.count, 1);
    
    [self.defaultLogController removeLogBlockWithKey:@"lobBlockTest"];
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.defaultLogController.logBlocks.allValues.count, 0);
    
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(logBlockTest.count, 0);
}

- (void)test_appendLog_logTrimming;
{
    NSUInteger numberOfLogsToEnter = 2 * self.defaultLogController.maximumLogCount + 10;
    NSUInteger expectedInternalLogCount = self.defaultLogController.maximumLogCount + (numberOfLogsToEnter % self.defaultLogController.maximumLogCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + self.defaultLogController.maximumLogCount); i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    // Wait until all logs are entered.
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(self.defaultLogController.logMessages.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(self.defaultLogController.maximumLogCount), @(expectedInternalLogCount), @(self.defaultLogController.logMessages.count));
    
    // Exposed log count should never be greater than maximumLogCount.
    NSArray *allLogMessages = self.defaultLogController.allLogMessages;
    XCTAssertGreaterThanOrEqual(allLogMessages.count, self.defaultLogController.maximumLogCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(allLogMessages.count), @(self.defaultLogController.maximumLogCount));
}

- (void)test_clearLogs_removesAllLogMessages;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController clearLogs];
    
    XCTAssertTrue(self.defaultLogController.logMessages.count == 0, @"Local logs have count of %@ after clearing!", @(self.defaultLogController.logMessages.count));
    XCTAssertTrue(self.defaultLogController.allLogMessages.count == 0, @"Local logs have count of %@ after clearing!", @(self.defaultLogController.allLogMessages.count));
}

- (void)test_clearLogs_removesPersistedLogs;
{
    XCTAssertNil([self.defaultLogController _persistedLogs]);
    
    ARKLog(@"Log");
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    [self.defaultLogController _persistLogs_inLoggingQueue];
    XCTAssertNotNil([self.defaultLogController _persistedLogs]);
    
    [self.defaultLogController clearLogs];
    XCTAssertNil([self.defaultLogController _persistedLogs]);
}

- (void)test_trimmedLogsToPersistLogs_maximumLogCountToPersistPersisted;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.defaultLogController.maximumLogCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    NSArray *logsToPerist = [self.defaultLogController _trimedLogsToPersist_inLoggingQueue];
    XCTAssertEqual(logsToPerist.count, self.defaultLogController.maximumLogCountToPersist);
}

- (void)test_persistLogs_noSideEffect;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.defaultLogController.maximumLogCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    [self.defaultLogController _persistLogs_inLoggingQueue];
    XCTAssertEqual(self.defaultLogController.logMessages.count, numberOfLogsToEnter, @"Persisting logs should not have affected internal log count");
}

- (void)test_setPersistedLogsFilePath_appendsLogsInPersistedObjects;
{
    ARKLogController *logController = [ARKLogController new];
    logController.loggingEnabled = YES;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *persistenceTestLogsPath = [applicationSupportDirectory stringByAppendingPathComponent:@"ARKPersistenceTestLogControllerLogs.data"];
    NSString *testPeristedLogMessageText = @"setpersistedLogsFilePath: test log";
    
    logController.persistedLogsFilePath = persistenceTestLogsPath;
    
    [logController appendLog:@"%@", testPeristedLogMessageText];
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    [logController _persistLogs_inLoggingQueue];
    
    XCTAssertEqualObjects([logController.logMessages.lastObject text], testPeristedLogMessageText);
    XCTAssertEqualObjects(logController.logMessages.firstObject, logController.logMessages.lastObject);
    
    ARKLogController *persistenceTestLogController = [ARKLogController new];
    XCTAssertEqual(persistenceTestLogController.logMessages.count, 0);
    
    persistenceTestLogController.persistedLogsFilePath = persistenceTestLogsPath;
    [persistenceTestLogController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqualObjects([persistenceTestLogController.allLogMessages.lastObject text], testPeristedLogMessageText, @"Setting persistedLogsFilePath did not load logs.");
    XCTAssertEqualObjects(persistenceTestLogController.logMessages.firstObject, persistenceTestLogController.logMessages.lastObject, @"Setting persistedLogsFilePath did not load logs.");
    
    [logController clearLogs];
    [persistenceTestLogController clearLogs];
}

- (void)test_dealloc_persistsLogs;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *persistenceTestLogsPath = [applicationSupportDirectory stringByAppendingPathComponent:@"ARKPersistenceTestLogControllerLogs.data"];
    
    ARKLogController *logController = [ARKLogController new];
    logController.loggingEnabled = YES;
    logController.persistedLogsFilePath = persistenceTestLogsPath;
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < logController.maximumLogCountToPersist; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        [logController appendLog:@"%@", number];
    }];
    
    // Get the log count.
    NSUInteger logMessageCount = logController.allLogMessages.count;
    XCTAssertEqual(logMessageCount, logController.maximumLogCountToPersist);
    
    // Persist logs to disk.
    [logController _persistLogs_inLoggingQueue];
    
    // Make sure that logController doesn't save logs on dealloc after this test finishes.
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    [logController.logMessages removeAllObjects];
    
    __weak ARKLogController *weakLogController = nil;
    ARKLogController *persistenceCheckLogController = nil;
    @autoreleasepool {
        // Create a new log controller.
        logController = [ARKLogController new];
        logController.persistedLogsFilePath = persistenceTestLogsPath;
        
        // Delete the persisted logs.
        [[NSFileManager defaultManager] removeItemAtPath:logController.persistedLogsFilePath error:NULL];
        
        // Ensure deleting the persisted logs removed all logs.
        persistenceCheckLogController = [ARKLogController new];
        persistenceCheckLogController.persistedLogsFilePath = persistenceTestLogsPath;
        XCTAssertEqual(persistenceCheckLogController.allLogMessages.count, 0, @"Removing file at persistedLogsFilePath did not remove logs!");
        
        weakLogController = logController;
        XCTAssertEqual(logController.allLogMessages.count, logMessageCount, @"New log controller did not initialize itself with logs from the previous controller!");
        
        // Make sure that persistenceCheckLogController doesn't save logs on dealloc after this test finishes.
        [persistenceCheckLogController.loggingQueue waitUntilAllOperationsAreFinished];
        [persistenceCheckLogController.logMessages removeAllObjects];
        
        logController = nil;
    }
    
    XCTAssertNil(weakLogController, @"Log controller should not be living after niling out reference");
    
    // Create a new log controller
    logController = [ARKLogController new];
    logController.persistedLogsFilePath = persistenceTestLogsPath;
    
    XCTAssertEqual(logController.allLogMessages.count, logMessageCount, @"Logs did not persist in dealloc.");
    
    [logController clearLogs];
}

#pragma mark - Performance Tests

- (void)test_appendLog_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_allLogMessages_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        // Trim and format the logs.
        (void)self.defaultLogController.allLogMessages;
    }];
}
- (void)test_trimLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            ARKLog(@"%@", number);
        }];
        
        [self.defaultLogController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.defaultLogController _trimLogs_inLoggingQueue];
        }];
        
        [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_persistLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        [self.defaultLogController.loggingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.defaultLogController _persistLogs_inLoggingQueue];
        }];
        
        [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    }];
}

@end
