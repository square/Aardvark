//
//  ARKLogFormatterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKDefaultLogFormatter.h"
#import "ARKLogController.h"
#import "ARKLogController_Testing.h"


@interface ARKLogFormatterTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogController *defaultLogController;
@property (nonatomic, strong, readwrite) ARKDefaultLogFormatter *logFormatter;

@end


@implementation ARKLogFormatterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogController = [ARKLogController defaultController];
    self.defaultLogController.loggingEnabled = YES;
    
    self.logFormatter = [ARKDefaultLogFormatter new];
}

- (void)tearDown;
{
    [self.defaultLogController clearLogs];

    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_formattedLogMessage_errorLogLineCount;
{
    ARKTypeLog(ARKLogTypeError, nil, @"Fake Error Log");
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 2, @"Logging an error should create two lines of formatted logs");
}

- (void)test_formattedLogMessage_separatorLogLineCount;
{
    ARKTypeLog(ARKLogTypeSeparator, nil, @"Separators Rule");
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 2, @"Logging a separator should create two lines of formatted logs");
}

- (void)test_formattedLogMessage_defaultLogLineCount;
{
    ARKLog(@"Something Happened");
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqual(splitLog.count, 1, @"Logging a default log should create one line of formatted logs");
}

- (void)test_formattedLogMessage_errorLogContent;
{
    NSString *errorLog = @"Fake Error Log";
    ARKTypeLog(ARKLogTypeError, nil, @"%@", errorLog);
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
    XCTAssertEqualObjects(splitLog.lastObject, [self.defaultLogController.logMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 2);
}

- (void)test_formattedLogMessage_separatorLogContent;
{
    NSString *separatorLog = @"Separators Rule";
    ARKTypeLog(ARKLogTypeSeparator, nil, @"%@", separatorLog);
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
    XCTAssertEqualObjects(splitLog.lastObject, [self.defaultLogController.logMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 2);
}

- (void)test_formattedLogMessage_defaultLogContent;
{
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, [self.defaultLogController.logMessages.firstObject description]);
    XCTAssertEqual(splitLog.count, 1);
}

- (void)test_formattedLogMessage_errorPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    
    ARKTypeLog(ARKLogTypeError, nil, @"Fake Error Log");
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
}

- (void)test_formattedLogMessage_separatorPrefixChangeRespected;
{
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKTypeLog(ARKLogTypeSeparator, nil, @"Separators Rule");
    NSString *formattedSingleLog = [self.logFormatter formattedLogMessage:self.defaultLogController.allLogMessages.firstObject];
    NSArray *splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
    XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
}

#pragma mark - Performance Tests

- (void)test_formattedLogMessage_performance;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        for (ARKLogMessage *logMessage in [self.defaultLogController allLogMessages]) {
            [self.logFormatter formattedLogMessage:logMessage];
        }
    }];
}

@end
