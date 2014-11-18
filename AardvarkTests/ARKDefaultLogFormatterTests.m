//
//  ARKDefaultLogFormatterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKDefaultLogFormatter.h"
#import "ARKLogDistributor.h"
#import "ARKLogStore.h"


@interface ARKDefaultLogFormatterTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic, strong, readwrite) ARKDefaultLogFormatter *logFormatter;
@property (nonatomic, weak, readwrite) ARKLogStore *logStore;

@end


@implementation ARKDefaultLogFormatterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    self.logFormatter = [ARKDefaultLogFormatter new];
    
    ARKLogStore *logStore = [ARKLogStore new];
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    self.logStore = logStore;
}

- (void)tearDown;
{
    [self.logStore clearLogs];
    
    // Wait for logs to clear.
    (void)[self.logStore allLogMessages];
    
    [ARKLogDistributor defaultDistributor].defaultLogStore = nil;
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_formattedLogMessage_errorLogLineCount;
{
    ARKLogWithType(ARKLogTypeError, nil, @"Fake Error Log");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 2, @"Logging an error should create two lines of formatted logs");
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
}

- (void)test_formattedLogMessage_separatorLogLineCount;
{
    ARKLogWithType(ARKLogTypeSeparator, nil, @"Separators Rule");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 2, @"Logging a separator should create two lines of formatted logs");
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
}

- (void)test_formattedLogMessage_defaultLogLineCount;
{
    ARKLog(@"Something Happened");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 1, @"Logging a default log should create one line of formatted logs");
}

- (void)test_formattedLogMessage_errorLogContent;
{
    NSString *errorLog = @"Fake Error Log";
    ARKLogWithType(ARKLogTypeError, nil, @"%@", errorLog);
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
    XCTAssertEqualObjects(splitLog.lastObject, [self.logStore.allLogMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 2);
}

- (void)test_formattedLogMessage_separatorLogContent;
{
    NSString *separatorLog = @"Separators Rule";
    ARKLogWithType(ARKLogTypeSeparator, nil, @"%@", separatorLog);
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
    XCTAssertEqualObjects(splitLog.lastObject, [self.logStore.allLogMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 2);
}

- (void)test_formattedLogMessage_defaultLogContent;
{
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, [self.logStore.allLogMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 1);
}

- (void)test_formattedLogMessage_errorPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    
    ARKLogWithType(ARKLogTypeError, nil, @"Fake Error Log");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
}

- (void)test_formattedLogMessage_separatorPrefixChangeRespected;
{
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKLogWithType(ARKLogTypeSeparator, nil, @"Separators Rule");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
}

- (void)test_formattedLogMessage_errorPrefixOnSameLineIfLogTextIsEmpty;
{
    ARKLogWithType(ARKLogTypeError, nil, @"");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 1);
}

- (void)test_formattedLogMessage_separatorPrefixOnSameLineIfLogTextIsEmpty;
{
    ARKLogWithType(ARKLogTypeSeparator, nil, @"");
    
    NSArray *logMessages = self.logStore.allLogMessages;
    XCTAssertEqual(logMessages.count, 1);
    
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:logMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 1);
}

#pragma mark - Performance Tests

- (void)test_formattedLogMessage_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        for (ARKLogMessage *logMessage in [self.logStore allLogMessages]) {
            [self.logFormatter formattedLogMessage:logMessage];
        }
    }];
}

@end
