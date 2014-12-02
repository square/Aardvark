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
#import "ARKLogDistributor_Testing.h"
#import "ARKLogMessage.h"


@interface ARKLogStoreTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogStore *logStore;
@property (nonatomic, strong, readwrite) ARKLogDistributor *logDistributor;

@end


@implementation ARKLogStoreTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"ARKLogStoreTests.data"];
    self.logDistributor = [ARKLogDistributor new];
    [self.logDistributor addLogObserver:self.logStore];
}

- (void)tearDown;
{
    [self.logDistributor removeLogObserver:self.logStore];
    
    [self.logStore clearLogs];
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_init_doesNotSetPersistencePath;
{
    XCTAssertNil([ARKLogStore new].persistedLogsFileURL);
}

- (void)test_observeLogMessage_logsLogToLogStore;
{
    [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Logging Enabled" image:nil type:ARKLogTypeDefault userInfo:nil]];

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1, @"Log not stored!");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_setMaximumLogCount_settingToZeroDestroysLogMessageArray;
{
    XCTAssertNotNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 0;
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(self.logStore.logMessages);
}

- (void)test_setMaximumLogCount_settingToZeroThenNonZeroRessurectsLogMessageArray;
{
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 0;
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(self.logStore.logMessages);
    
    self.logStore.maximumLogMessageCount = 5;
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil(self.logStore.logMessages);
}

- (void)test_logFilterBlock_preventsLogsFromBeingObserved;
{
    NSString *const ARKLogStoreTestShouldLogKey = @"ARKLogStoreTestShouldLog";
    
    self.logStore.logFilterBlock = ^(ARKLogMessage *logMessage) {
        return [logMessage.userInfo[ARKLogStoreTestShouldLogKey] boolValue];
    };
    
    NSDictionary *userInfo = @{ ARKLogStoreTestShouldLogKey : @NO };
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault userInfo:userInfo]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 0);
        
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Log This Log" image:nil type:ARKLogTypeDefault userInfo:@{ ARKLogStoreTestShouldLogKey : @YES }]];
        
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            XCTAssertEqual(logMessages.count, 1);
            
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Do Not Log This Log" image:nil type:ARKLogTypeDefault userInfo:nil]];
            
            [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
                XCTAssertEqual(logMessages.count, 1);
                
                [expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_observeLogMessage_logTrimming;
{
    NSUInteger numberOfLogsToEnter = 2 * self.logStore.maximumLogMessageCount + 10;
    NSUInteger expectedInternalLogCount = self.logStore.maximumLogMessageCount + (numberOfLogsToEnter % self.logStore.maximumLogMessageCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + self.logStore.maximumLogMessageCount); i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];
    
    // Wait until all logs are entered.
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(self.logStore.logMessages.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(self.logStore.maximumLogMessageCount), @(expectedInternalLogCount), @(self.logStore.logMessages.count));
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        // Exposed log count should never be greater than maximumLogCount.
        XCTAssertGreaterThanOrEqual(logMessages.count, self.logStore.maximumLogMessageCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(logMessages.count), @(self.logStore.maximumLogMessageCount));
        
        [expectation fulfill];
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

- (void)test_clearLogs_removesAllLogMessages;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore clearLogs];
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue(self.logStore.logMessages.count == 0, @"Local logs have count of %@ after clearing!", @(self.logStore.logMessages.count));
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertTrue(logMessages.count == 0, @"Local logs have count of %@ after clearing!", @(logMessages.count));
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_clearLogs_removesPersistedLogs;
{
    // Remove the log store so we don't have to wait for the log distrbutor when clearing logs.
    [self.logDistributor removeLogObserver:self.logStore];
    
    XCTAssertNil([self.logStore _persistedLogs]);
    
    [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:@"Log" image:nil type:ARKLogTypeDefault userInfo:nil]];
    [self.logStore.logObservingQueue addOperationWithBlock:^{
        [self.logStore _persistLogs_inLogObservingQueue];
    }];
    
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil([self.logStore _persistedLogs]);
    
    [self.logStore clearLogs];
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil([self.logStore _persistedLogs]);
}

- (void)test_trimLogs_trimsOldestLogs;
{
    self.logStore.maximumLogMessageCount = 5;
    
    NSString *lastLogText = nil;
    for (NSUInteger i  = 0; i < self.logStore.maximumLogMessageCount + 1; i++) {
        lastLogText = [NSString stringWithFormat:@"Log %@", @(i)];
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:lastLogText image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        ARKLogMessage *lastLog = logMessages.lastObject;
        XCTAssertEqualObjects(lastLog.text, lastLogText);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_trimmedLogsToPersistLogs_maximumLogCountToPersistPersisted;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logStore.maximumLogMessageCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore _trimmedLogsToPersist_inLogObservingQueue:^(NSArray *logsToPersist) {
        XCTAssertEqual(logsToPersist.count, self.logStore.maximumLogCountToPersist);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_persistLogs_noSideEffect;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.logStore.maximumLogMessageCount + 10;
    for (NSUInteger i  = 0; i < numberOfLogsToEnter; i++) {
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"Log %@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    [self.logStore _persistLogs_inLogObservingQueue];
    [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(self.logStore.logMessages.count, numberOfLogsToEnter, @"Persisting logs should not have affected internal log count");
}

- (void)test_setPersistedLogsFileURL_observesPersistedLogsAtFileURL;
{
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"ARKPersistenceTestLogStoreLogs_setPersistedLogsFileURL.data"];
    
    NSURL *persistenceTestLogsURL = logStore.persistedLogsFileURL;
    NSString *testPeristedLogMessageText = @"setPersistedLogsFileURL: test log";
    
    [logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:testPeristedLogMessageText image:nil type:ARKLogTypeDefault userInfo:nil]];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    [logStore _persistLogs_inLogObservingQueue];
    
    XCTAssertEqualObjects([logStore.logMessages.lastObject text], testPeristedLogMessageText);
    XCTAssertEqualObjects(logStore.logMessages.firstObject, logStore.logMessages.lastObject);
    
    ARKLogStore *persistenceTestLogStore = [ARKLogStore new];
    XCTAssertEqual(persistenceTestLogStore.logMessages.count, 0);
    
    persistenceTestLogStore.persistedLogsFileURL = persistenceTestLogsURL;
    [persistenceTestLogStore.logObservingQueue waitUntilAllOperationsAreFinished];

    XCTAssertEqualObjects(persistenceTestLogStore.logMessages.firstObject, persistenceTestLogStore.logMessages.lastObject, @"Setting persistedLogsFilePath did not load logs.");
    
    // Create a distributor so retreiving log messages works.
    ARKLogDistributor *distributor = [ARKLogDistributor new];
    [distributor addLogObserver:logStore];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqualObjects([logMessages.lastObject text], testPeristedLogMessageText, @"Setting persistedLogsFilePath did not load logs.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    [distributor removeLogObserver:logStore];
    
    [logStore clearLogs];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    [persistenceTestLogStore clearLogs];
    [persistenceTestLogStore.logObservingQueue waitUntilAllOperationsAreFinished];
}

- (void)test_dealloc_persistsLogs;
{
    NSString *persistedLogFileName = @"ARKPersistenceTestLogStoreLogs_dealloc.data";
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:persistedLogFileName];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
        [logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];
    
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    // Get the log count.
    XCTAssertEqual(logStore.logMessages.count, numbers.count);
    
    // Persist logs to disk.
    [logStore.logObservingQueue addOperationWithBlock:^{
        [logStore _persistLogs_inLogObservingQueue];
    }];
    
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    // Make sure that logStore doesn't save logs on dealloc after this test finishes.
    [logStore.logMessages removeAllObjects];
    
    __weak ARKLogStore *weakLogStore = nil;
    ARKLogStore *persistenceCheckLogStore = nil;
    @autoreleasepool {
        // Create a new log store.
        logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:persistedLogFileName];
        
        // Delete the persisted logs.
        [[NSFileManager defaultManager] removeItemAtURL:logStore.persistedLogsFileURL error:NULL];
        
        // Ensure deleting the persisted logs removed all logs.
        persistenceCheckLogStore = [[ARKLogStore alloc] initWithPersistedLogFileName:persistedLogFileName];
        [persistenceCheckLogStore.logObservingQueue waitUntilAllOperationsAreFinished];
        XCTAssertEqual(persistenceCheckLogStore.logMessages.count, 0, @"Removing file at persistedLogsFilePath did not remove logs!");
        
        weakLogStore = logStore;
        [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
        XCTAssertEqual(logStore.logMessages.count, numbers.count, @"New log store did not initialize itself with logs from the previous controller!");
        
        // Make sure that persistenceCheckLogStore doesn't save logs on dealloc after this test finishes.
        [persistenceCheckLogStore.logObservingQueue waitUntilAllOperationsAreFinished];
        [persistenceCheckLogStore.logMessages removeAllObjects];
        
        logStore = nil;
    }
    
    XCTAssertNil(weakLogStore, @"Log controller should not be living after niling out reference");
    
    // Create a new log store.
    logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:persistedLogFileName];

    // Create a distributor so retreiving log messages works.
    ARKLogDistributor *distributor = [ARKLogDistributor new];
    [distributor addLogObserver:logStore];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logStore.logMessages.count, numbers.count, @"Logs did not persist in dealloc.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    [logStore clearLogs];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    [distributor.logDistributingQueue waitUntilAllOperationsAreFinished];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
}

- (void)test_initializeLogMessages_ressurectsAtMostMaximumLogCount;
{
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:@"ARKPersistenceTestLogStoreLogs_initializeLogMessages.data"];
    logStore.maximumLogMessageCount = 10;
    for (int i = 0; i < logStore.maximumLogMessageCount; i++) {
        [logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault userInfo:nil]];
    }
    
    [logStore.logObservingQueue addOperationWithBlock:^{
        [logStore _persistLogs_inLogObservingQueue];
    }];
    
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    
    logStore.maximumLogMessageCount = 0;
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(logStore.logMessages);
    
    logStore.maximumLogMessageCount = 5;
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(logStore.logMessages.count, logStore.maximumLogMessageCount);
    
    [logStore clearLogs];
    [logStore.logObservingQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Performance Tests

- (void)test_log_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
    }];
}

- (void)test_retrieveAllLogMessagesWithCompletionHandler_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.logStore.maximumLogCountToPersist; i++) {
        [numbers addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    
    [self measureBlock:^{
        // Concurrently add all of the logs.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *text, NSUInteger idx, BOOL *stop) {
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
        
        // Trim and format the logs.
        XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
        
        [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
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
            [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
        }];
        
        [self.logStore.logObservingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logStore _trimLogs_inLogObservingQueue];
        }];
        
        [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
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
        [self.logStore observeLogMessage:[[ARKLogMessage alloc] initWithText:text image:nil type:ARKLogTypeDefault userInfo:nil]];
    }];

    [self measureBlock:^{
        [self.logStore.logObservingQueue addOperationWithBlock:^{
            // Trim and persist the logs.
            [self.logStore _persistLogs_inLogObservingQueue];
        }];
        
        [self.logStore.logObservingQueue waitUntilAllOperationsAreFinished];
    }];
}

@end
