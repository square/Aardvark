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

- (void)test_formattedLogMessages_errorLogLineCount;
{
    ARKTypeLog(ARKLogTypeError, nil, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging an error should create two lines of formatted logs");
}

- (void)test_formattedLogMessages_separatorLogLineCount;
{
    ARKTypeLog(ARKLogTypeSeparator, nil, @"Separators Rule");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging a separator should create two lines of formatted logs");
}

- (void)test_formattedLogMessages_defaultLogLineCount;
{
    ARKLog(@"Something Happened");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqual(formattedSingleLog.count, 1, @"Logging a default log should create one line of formatted logs");
}

- (void)test_formattedLogMessages_errorLogContent;
{
    NSString *errorLog = @"Fake Error Log";
    ARKTypeLog(ARKLogTypeError, nil, @"%@", errorLog);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.errorLogPrefix stringByAppendingString:@"\n"]);
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[self.defaultLogController.logMessages.firstObject description] stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogMessages_separatorLogContent;
{
    NSString *separatorLog = @"Separators Rule";
    ARKTypeLog(ARKLogTypeSeparator, nil, @"%@", separatorLog);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.separatorLogPrefix stringByAppendingString:@"\n"]);
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[self.defaultLogController.logMessages.firstObject description] stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogMessages_defaultLogContent;
{
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[self.defaultLogController.logMessages.firstObject description] stringByAppendingString:@"\n"]);
    XCTAssertEqual(formattedSingleLog.count, 1);
}

- (void)test_formattedLogMessagesAsData_formattedLogMessagesAsPlainText_equivalentData;
{
    ARKLog(@"Test Log 1");
    ARKLog(@"Test Log 2");
    ARKLog(@"Test Log 3");
    
    NSData *formattedLogData = [self.logFormatter formattedLogMessagesAsData:self.defaultLogController.allLogMessages];
    NSString *formattedLogMessages = [self.logFormatter formattedLogMessagesAsPlainText:self.defaultLogController.allLogMessages];
    
    XCTAssertEqualObjects([[NSString alloc] initWithData:formattedLogData encoding:NSUTF8StringEncoding], formattedLogMessages);
}

- (void)test_formattedLogMessages_errorPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    
    ARKTypeLog(ARKLogTypeError, nil, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.errorLogPrefix stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogMessages_separatorPrefixChangeRespected;
{
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKTypeLog(ARKLogTypeSeparator, nil, @"Separators Rule");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogMessagesWithImages:self.defaultLogController.allLogMessages];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.separatorLogPrefix stringByAppendingString:@"\n"]);
}

- (void)test_recentErrorLogMessagesAsPlainText_countRespected;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < self.defaultLogController.maximumLogMessageCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKTypeLog(ARKLogTypeError, nil, @"%@", number);
    }];
    
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.logFormatter recentErrorLogMessagesAsPlainText:self.defaultLogController.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqual([recentErrorLogs componentsSeparatedByString:@"\n"].count, numberOfRecentErrorLogs);
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfNoErrorLogsPresent;
{
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.logFormatter recentErrorLogMessagesAsPlainText:self.defaultLogController.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
    
    ARKLog(@"This is not an error");
    
    recentErrorLogs = [self.logFormatter recentErrorLogMessagesAsPlainText:self.defaultLogController.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
}

#pragma mark - Performance Tests

- (void)test_formattedLogMessages_performance;
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
        [self.logFormatter formattedLogMessagesWithImages:[self.defaultLogController allLogMessages]];
    }];
}

@end
