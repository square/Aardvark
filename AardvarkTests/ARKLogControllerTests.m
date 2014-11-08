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
#import "ARKLogHandler.h"
#import "ARKLogMessage.h"


@interface ARKLogControllerTests : XCTestCase

@property (nonatomic, weak, readwrite) ARKLogController *defaultLogController;

@end


typedef void (^LogHandlingBlock)(ARKLogController *logController, ARKLogMessage *logMessage);


@interface ARKTestLogHandler : NSObject <ARKLogHandler>

@property (nonatomic, copy, readwrite) LogHandlingBlock logHandlingBlock;

@end


@implementation ARKTestLogHandler

- (void)logController:(ARKLogController *)logController didAppendLogMessage:(ARKLogMessage *)logMessage;
{
    if (self.logHandlingBlock) {
        self.logHandlingBlock(logController, logMessage);
    }
}

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
    XCTAssertNotNil(self.defaultLogController.persistedLogsFileURL);
}

- (void)test_init_doesNotSetPersistencePath;
{
    XCTAssertNotNil([ARKLogController new].persistedLogsFileURL);
}

- (void)test_loggingEnabled_loggingInitiallyDisabled;
{
    ARKLogController *logController = [ARKLogController new];
    
    [logController appendLogWithFormat:@"Logging Disabled"];
    
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

- (void)test_setLogMessageClass_appendedLogsAreCorrectClass;
{
    ARKLogController *logController = [ARKLogController new];
    logController.loggingEnabled = YES;
    
    [logController appendLogWithFormat:@"This log should be an ARKLogMessage"];
    
    XCTAssertEqual(logController.allLogMessages.count, 1);
    XCTAssertEqual([logController.allLogMessages.firstObject class], [ARKLogMessage class]);
    
    [logController clearLogs];
    XCTAssertEqual(logController.allLogMessages.count, 0);
    
    logController.logMessageClass = [ARKLogMessageTestSubclass class];
    [logController appendLogWithFormat:@"This log should be an ARKLogMessageTestSubclass"];
    
    XCTAssertEqual(logController.allLogMessages.count, 1);
    XCTAssertEqual([logController.allLogMessages.firstObject class], [ARKLogMessageTestSubclass class]);
}

- (void)test_setMaximumLogCount_settingToZeroDestroysLogMessageArray;
{
    ARKLogController *logController = [ARKLogController new];
    XCTAssertNotNil(logController.logMessages);
    
    logController.maximumLogMessageCount = 0;
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(logController.logMessages);
}

- (void)test_setMaximumLogCount_settingToZeroThenNonZeroRessurectsLogMessageArray;
{
    ARKLogController *logController = [ARKLogController new];
    XCTAssertNotNil(logController.logMessages);
    
    logController.maximumLogMessageCount = 0;
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(logController.logMessages);
    
    logController.maximumLogMessageCount = 5;
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNotNil(logController.logMessages);
}

- (void)_test_setMaximumLogCount_settingToZeroStillCallsLogHandlers;
{
    ARKLogController *logController = [ARKLogController new];
    logController.maximumLogMessageCount = 0;
    logController.loggingEnabled = YES;
    
    NSMutableArray *logHandlerTest = [NSMutableArray new];
    ARKTestLogHandler *testLogHandler = [ARKTestLogHandler new];
    testLogHandler.logHandlingBlock = ^(ARKLogController *logController, ARKLogMessage *logMessage) {
        [logHandlerTest addObject:logMessage];
    };
    [logController addLogHandler:testLogHandler];
    
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
        [logController appendLogWithFormat:@"Log %@", @(i)];
    }
    
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertGreaterThan(logController.logMessages.count, 0);
    [logController.logMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(logMessage, logHandlerTest[idx]);
    }];
}

- (void)test_addLogHandler_notifiesLogHandlerOnAppendLog;
{
    NSMutableArray *logHandlerTest = [NSMutableArray new];
    ARKTestLogHandler *testLogHandler = [ARKTestLogHandler new];
    testLogHandler.logHandlingBlock = ^(ARKLogController *logController, ARKLogMessage *logMessage) {
        [logHandlerTest addObject:logMessage];
    };
    [self.defaultLogController addLogHandler:testLogHandler];
    
    XCTAssertEqual(logHandlerTest.count, 0);
    
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertGreaterThan(self.defaultLogController.logMessages.count, 0);
    [self.defaultLogController.logMessages enumerateObjectsUsingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(logMessage, logHandlerTest[idx]);
    }];
    
    [self.defaultLogController removeLogHandler:testLogHandler];
}

- (void)test_removeLobHandler_removesLogHandler;
{
    NSMutableArray *logHandlerTest = [NSMutableArray new];
    ARKTestLogHandler *testLogHandler = [ARKTestLogHandler new];
    testLogHandler.logHandlingBlock = ^(ARKLogController *logController, ARKLogMessage *logMessage) {
        [logHandlerTest addObject:logMessage];
    };
    
    [self.defaultLogController addLogHandler:testLogHandler];
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.defaultLogController.logHandlers.count, 1);
    
    [self.defaultLogController removeLogHandler:testLogHandler];
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertEqual(self.defaultLogController.logHandlers.count, 0);
    
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(logHandlerTest.count, 0);
}

- (void)test_appendLog_logTrimming;
{
    NSUInteger numberOfLogsToEnter = 2 * self.defaultLogController.maximumLogMessageCount + 10;
    NSUInteger expectedInternalLogCount = self.defaultLogController.maximumLogMessageCount + (numberOfLogsToEnter % self.defaultLogController.maximumLogMessageCount);
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < (expectedInternalLogCount + self.defaultLogController.maximumLogMessageCount); i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    // Wait until all logs are entered.
    [self.defaultLogController.loggingQueue waitUntilAllOperationsAreFinished];
    
    // Internal log count should be proactively truncated at 2 * maximumLogCount.
    XCTAssertEqual(self.defaultLogController.logMessages.count, expectedInternalLogCount, @"Expected internal log count to be proactively truncated to (%@) at 2 * maximumLogCount. Expected internal log count of %@, got %@.", @(self.defaultLogController.maximumLogMessageCount), @(expectedInternalLogCount), @(self.defaultLogController.logMessages.count));
    
    // Exposed log count should never be greater than maximumLogCount.
    NSArray *allLogMessages = self.defaultLogController.allLogMessages;
    XCTAssertGreaterThanOrEqual(allLogMessages.count, self.defaultLogController.maximumLogMessageCount, @"Exposed log count (%@) must never exceed maximum log count (%@).", @(allLogMessages.count), @(self.defaultLogController.maximumLogMessageCount));
}

- (void)test_clearLogs_removesAllLogMessages;
{
    // Fill in some logs.
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
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

- (void)test_trimLogs_trimsOldestLogs;
{
    self.defaultLogController.maximumLogMessageCount = 5;
    
    NSString *lastLogText = nil;
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount + 1; i++) {
        lastLogText = [NSString stringWithFormat:@"Log %@", @(i)];
        ARKLog(@"%@", lastLogText);
    }
    
    NSArray *logMessages = self.defaultLogController.allLogMessages;
    ARKLogMessage *lastLog = logMessages.lastObject;
    XCTAssertEqualObjects(lastLog.text, lastLogText);
}

- (void)test_trimmedLogsToPersistLogs_maximumLogCountToPersistPersisted;
{
    // Fill in some logs.
    NSUInteger numberOfLogsToEnter = self.defaultLogController.maximumLogMessageCount + 10;
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
    NSUInteger numberOfLogsToEnter = self.defaultLogController.maximumLogMessageCount + 10;
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
    
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogControllerLogs.data"];
    NSString *testPeristedLogMessageText = @"setpersistedLogsFilePath: test log";
    
    logController.persistedLogsFileURL = persistenceTestLogsURL;
    
    [logController appendLogWithFormat:@"%@", testPeristedLogMessageText];
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    [logController _persistLogs_inLoggingQueue];
    
    XCTAssertEqualObjects([logController.logMessages.lastObject text], testPeristedLogMessageText);
    XCTAssertEqualObjects(logController.logMessages.firstObject, logController.logMessages.lastObject);
    
    ARKLogController *persistenceTestLogController = [ARKLogController new];
    XCTAssertEqual(persistenceTestLogController.logMessages.count, 0);
    
    persistenceTestLogController.persistedLogsFileURL = persistenceTestLogsURL;
    [persistenceTestLogController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqualObjects([persistenceTestLogController.allLogMessages.lastObject text], testPeristedLogMessageText, @"Setting persistedLogsFilePath did not load logs.");
    XCTAssertEqualObjects(persistenceTestLogController.logMessages.firstObject, persistenceTestLogController.logMessages.lastObject, @"Setting persistedLogsFilePath did not load logs.");
    
    [logController clearLogs];
    [persistenceTestLogController clearLogs];
}

- (void)test_dealloc_persistsLogs;
{
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogControllerLogs.data"];
    
    ARKLogController *logController = [ARKLogController new];
    logController.loggingEnabled = YES;
    logController.persistedLogsFileURL = persistenceTestLogsURL;
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < logController.maximumLogCountToPersist; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        [logController appendLogWithFormat:@"%@", number];
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
        logController.persistedLogsFileURL = persistenceTestLogsURL;
        
        // Delete the persisted logs.
        [[NSFileManager defaultManager] removeItemAtURL:logController.persistedLogsFileURL error:NULL];
        
        // Ensure deleting the persisted logs removed all logs.
        persistenceCheckLogController = [ARKLogController new];
        persistenceCheckLogController.persistedLogsFileURL = persistenceTestLogsURL;
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
    logController.persistedLogsFileURL = persistenceTestLogsURL;
    
    XCTAssertEqual(logController.allLogMessages.count, logMessageCount, @"Logs did not persist in dealloc.");
    
    [logController clearLogs];
}

- (void)test_initializeLogMessages_ressurectsAtMostMaximumLogCount;
{
    ARKLogController *logController = [ARKLogController new];
    logController.loggingEnabled = YES;
    logController.maximumLogMessageCount = 10;
    for (int i = 0; i < logController.maximumLogMessageCount; i++) {
        [logController appendLogWithFormat:@"%@", @(i)];
    }
    
    NSURL *persistenceTestLogsURL = [self _persistenceURLWithFileName:@"ARKPersistenceTestLogControllerLogs.data"];
    
    logController.persistedLogsFileURL = persistenceTestLogsURL;
    
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    [logController _persistLogs_inLoggingQueue];
    
    logController.maximumLogMessageCount = 0;
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertNil(logController.logMessages);
    
    logController.maximumLogMessageCount = 5;
    [logController.loggingQueue waitUntilAllOperationsAreFinished];
    XCTAssertEqual(logController.logMessages.count, logController.maximumLogMessageCount);
    
    [logController clearLogs];
}

#pragma mark - Performance Tests

- (void)test_appendLog_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogMessageCount; i++) {
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
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogMessageCount; i++) {
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
    for (NSUInteger i  = 0; i < 3 * self.defaultLogController.maximumLogMessageCount; i++) {
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
    for (NSUInteger i  = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
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

#pragma mark - Private Methods

- (NSURL *)_persistenceURLWithFileName:(NSString *)fileName;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *persistenceTestLogsPath = [applicationSupportDirectory stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:persistenceTestLogsPath isDirectory:NO];
}

@end
