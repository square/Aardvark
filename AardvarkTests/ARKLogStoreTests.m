//
//  ARKLogStoreTests.m
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"

#import "ARKLogDistributor.h"
#import "ARKLogMessage.h"


@interface ARKLogStoreTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogStore *logStore;


@end


@implementation ARKLogStoreTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.logStore = [ARKLogStore new];
    self.logStore.persistedLogsFileURL = [self _persistenceURLWithFileName:@"ARKLogStoreTests.data"];
}

- (void)tearDown;
{
    [self.logStore clearLogs];
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_init_doesNotSetPersistencePath;
{
    XCTAssertNil([ARKLogStore new].persistedLogsFileURL);
}

- (void)test_ARKLog_appendsLogToLogStore;
{
    [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:@"Logging Enabled" image:nil type:ARKLogTypeDefault userInfo:nil]];
    
    XCTAssertEqual(self.logStore.allLogMessages.count, 1, @"Log not appended with logging enabled!");
}

- (void)test_setMaximumLogCount_settingToZeroDestroysLogMessageArray;
{
    XCTAssertNotNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 0;
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(self.logStore.logMessages);
}

- (void)test_setMaximumLogCount_settingToZeroThenNonZeroRessurectsLogMessageArray;
{
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 0;
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 5;
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil(self.logStore.logMessages);
}

- (void)test_appendLog_logTrimming;
{
    NSUInteger numberOfLogsToEnter = 2 * self.logStore.maximumLogMessageCount + 10;
    NSUInteger expectedInternalLogCount = self.logStore.maximumLogMessageCount + (numberOfLogsToEnter % self.logStore.maximumLogMessageCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + self.logStore.maximumLogMessageCount); i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];
    
    // Wait until all logs are entered.
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(self.logStore.logMessages.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(self.logStore.maximumLogMessageCount), @(expectedInternalLogCount), @(self.logStore.logMessages.count));
    
    // Exposed log count should never be greater than maximumLogCount.
    NSArray *allLogMessages = self.logStore.allLogMessages;
    XCTAssertGreaterThanOrEqual(allLogMessages.count, self.logStore.maximumLogMessageCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(allLogMessages.count), @(self.logStore.maximumLogMessageCount));
}

- (void)test_allLogMessages_capturesAllLogsLogged;
{
    [ARKLogDistributor setDefaultLogStore:self.logStore];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently append all of the logs to the default log distributor.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", text);
    }];
    
    [ARKLogDistributor setDefaultLogStore:nil];
    
    XCTAssertEqual(self.logStore.allLogMessages.count, numbers.count);
}

- (void)test_clearLogs_removesAllLogMessages;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore clearLogs];
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue(self.logStore.logMessages.count == 0, @"Local logs have count of %@ after clearing!", @(self.logStore.logMessages.count));
    XCTAssertTrue(self.logStore.allLogMessages.count == 0, @"Local logs have count of %@ after clearing!", @(self.logStore.allLogMessages.count));
}

- (void)test_clearLogs_removesPersistedLogs;
{
    XCTAssertNil([self.logStore _persistedLogs]);
    
    [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:@"Log" image:nil type:ARKLogTypeDefault userInfo:nil]];
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    [self.logStore _persistLogs_inLogConsumingQueue];
    XCTAssertNotNil([self.logStore _persistedLogs]);
    
    [self.logStore clearLogs];
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil([self.logStore _persistedLogs]);
}

- (void)test_trimLogs_trimsOldestLogs;
{
    self.logStore.maximumLogMessageCount = 5;
    
    NSString *lastLogText = nil;
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount + 1; i++) {
        lastLogText = [NSString stringWithFormat:@"Log %@", @(i)];
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:lastLogText image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    NSArray *logMessages = self.logStore.allLogMessages;
    ARKLogMessage *lastLog = logMessages.lastObject;
    XCTAssertEqualObjects(lastLog.text, lastLogText);
}

- (void)test_trimmedLogsToPersistLogs_maximumLogCountToPersistPersisted;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logStore.maximumLogMessageCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    
    NSArray *logsToPerist = [self.logStore _trimmedLogsToPersist_inLogConsumingQueue];
    XCTAssertEqual(logsToPerist.count, self.logStore.maximumLogCountToPersist);
}

- (void)test_persistLogs_noSideEffect;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logStore.maximumLogMessageCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    
    [self.logStore _persistLogs_inLogConsumingQueue];
    [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(self.logStore.logMessages.count, numberOfLogsToEnter, @"Persisting logs should not have affected internal log count");
}

- (void)test_setPersistedLogsFilePath_appendsLogsInPersistedObjects;
{
    ARKLogStore *logStore = [ARKLogStore new];
    
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogDistributorLogs.data"];
    NSString *testPeristedLogMessageText = @"setpersistedLogsFilePath: test log";
    
    logStore.persistedLogsFileURL = persistenceTestLogsURL;
    
    [logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:testPeristedLogMessageText image:nil type:ARKLogTypeDefault userInfo:nil]];
    [logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    [logStore _persistLogs_inLogConsumingQueue];
    
    XCTAssertEqualObjects([logStore.logMessages.lastObject text], testPeristedLogMessageText);
    XCTAssertEqualObjects(logStore.logMessages.firstObject, logStore.logMessages.lastObject);
    
    ARKLogStore *persistenceTestLogStore = [ARKLogStore new];
    XCTAssertEqual(persistenceTestLogStore.logMessages.count, 0);
    
    persistenceTestLogStore.persistedLogsFileURL = persistenceTestLogsURL;
    [persistenceTestLogStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqualObjects([persistenceTestLogStore.allLogMessages.lastObject text], testPeristedLogMessageText, @"Setting persistedLogsFilePath did not load logs.");
    XCTAssertEqualObjects(persistenceTestLogStore.logMessages.firstObject, persistenceTestLogStore.logMessages.lastObject, @"Setting persistedLogsFilePath did not load logs.");
    
    [logStore clearLogs];
    [persistenceTestLogStore clearLogs];
}

- (void)test_dealloc_persistsLogs;
{
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogDistributorLogs.data"];
    
    ARKLogStore *logStore = [ARKLogStore new];
    logStore.persistedLogsFileURL = persistenceTestLogsURL;
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];
    
    // Get the log count.
    NSUInteger logMessageCount = logStore.allLogMessages.count;
    XCTAssertEqual(logMessageCount, logStore.maximumLogCountToPersist);
    
    // Persist logs to disk.
    [logStore _persistLogs_inLogConsumingQueue];
    
    // Make sure that logDistributor doesn't save logs on dealloc after this test finishes.
    [logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    [logStore.logMessages removeAllObjects];
    
    __weak ARKLogStore *weakLogStore = nil;
    ARKLogStore *persistenceCheckLogStore = nil;
    @autoreleasepool {
        // Create a new log distributor.
        logStore = [ARKLogStore new];
        logStore.persistedLogsFileURL = persistenceTestLogsURL;
        
        // Delete the persisted logs.
        [[NSFileManager defaultManager] removeItemAtURL:logStore.persistedLogsFileURL error:NULL];
        
        // Ensure deleting the persisted logs removed all logs.
        persistenceCheckLogStore = [ARKLogStore new];
        persistenceCheckLogStore.persistedLogsFileURL = persistenceTestLogsURL;
        XCTAssertEqual(persistenceCheckLogStore.allLogMessages.count, 0, @"Removing file at persistedLogsFilePath did not remove logs!");
        
        weakLogStore = logStore;
        XCTAssertEqual(logStore.allLogMessages.count, logMessageCount, @"New log distributor did not initialize itself with logs from the previous controller!");
        
        // Make sure that persistenceCheckLogStore doesn't save logs on dealloc after this test finishes.
        [persistenceCheckLogStore.logConsumingQueue waitUntilAllOperationsAreFinished];
        [persistenceCheckLogStore.logMessages removeAllObjects];
        
        logStore = nil;
    }
    
    XCTAssertNil(weakLogStore, @"Log controller should not be living after niling out reference");
    
    // Create a new log distributor
    logStore = [ARKLogStore new];
    logStore.persistedLogsFileURL = persistenceTestLogsURL;
    
    XCTAssertEqual(logStore.allLogMessages.count, logMessageCount, @"Logs did not persist in dealloc.");
    
    [logStore clearLogs];
}

- (void)test_initializeLogMessages_ressurectsAtMostMaximumLogCount;
{
    ARKLogStore *logStore = [ARKLogStore new];
    logStore.maximumLogMessageCount = 10;
    for (int i = 0; i < logStore.maximumLogMessageCount; i++) {
        [logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogDistributorLogs.data"];
    
    logStore.persistedLogsFileURL = persistenceTestLogsURL;
    
    [logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    [logStore _persistLogs_inLogConsumingQueue];
    
    logStore.maximumLogMessageCount = 0;
    [logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(logStore.logMessages);
    
    logStore.maximumLogMessageCount = 5;
    [logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(logStore.logMessages.count, logStore.maximumLogMessageCount);
    
    [logStore clearLogs];
}

#pragma mark - Performance Tests

- (void)test_appendLog_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
        
        [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_allLogMessages_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
        
        // Trim and format the logs.
        (void)self.logStore.allLogMessages;
    }];
}

- (void)test_trimLogs_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
        
        [self.logStore.logConsumingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logStore _trimLogs_inLogConsumingQueue];
        }];
        
        [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
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
        [self.logStore consumeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];

    [self measureBlock:^{
        [self.logStore.logConsumingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logStore _persistLogs_inLogConsumingQueue];
        }];
        
        [self.logStore.logConsumingQueue waitUntilAllOperationsAreFinished];
    }];
}

#pragma mark - Private Methods

- (NSURL *)_persistenceURLWithFileName:(NSString *)fileName;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *persistenceTestLogsPath = [applicationSupportDirectory stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:persistenceTestLogsPath isDirectory:NO];
}

@end
