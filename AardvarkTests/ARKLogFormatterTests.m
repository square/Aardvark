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

@property (nonatomic, strong, readwrite) ARKDefaultLogFormatter *logFormatter;

@end


@implementation ARKLogFormatterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    [Aardvark enableDefaultLogController];
    self.logFormatter = [ARKDefaultLogFormatter new];
}

- (void)tearDown;
{
    [[ARKLogController defaultController] clearLogs];

    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_formattedLogs_errorLogLineCount;
{
    ARKTypeLog(ARKLogTypeError, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging an error should create two lines of formatted logs");
}

- (void)test_formattedLogs_separatorLogLineCount;
{
    ARKTypeLog(ARKLogTypeSeparator, @"Separators Rule");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging a separator should create two lines of formatted logs");
}

- (void)test_formattedLogs_defaultLogLineCount;
{
    ARKLog(@"Something Happened");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 1, @"Logging a default log should create one line of formatted logs");
}

- (void)test_formattedLogs_errorLogContent;
{
    NSString *errorLog = @"Fake Error Log";
    ARKTypeLog(ARKLogTypeError, @"%@", errorLog);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.errorLogPrefix stringByAppendingString:@"\n"]);
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController defaultController].logs.firstObject description] stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogs_separatorLogContent;
{
    NSString *separatorLog = @"Separators Rule";
    ARKTypeLog(ARKLogTypeSeparator, @"%@", separatorLog);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.separatorLogPrefix stringByAppendingString:@"\n"]);
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController defaultController].logs.firstObject description] stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogs_defaultLogContent;
{
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController defaultController].logs.firstObject description] stringByAppendingString:@"\n"]);
    XCTAssertEqual(formattedSingleLog.count, 1);
}

- (void)test_formattedLogsAsData_formattedLogsAsPlainText_equivalentData;
{
    ARKLog(@"Test Log 1");
    ARKLog(@"Test Log 2");
    ARKLog(@"Test Log 3");
    
    NSData *formattedLogData = [self.logFormatter formattedLogsAsData:[ARKLogController defaultController].allLogs];
    NSString *formattedLogs = [self.logFormatter formattedLogsAsPlainText:[ARKLogController defaultController].allLogs];
    
    XCTAssertEqualObjects([[NSString alloc] initWithData:formattedLogData encoding:NSUTF8StringEncoding], formattedLogs);
}

- (void)test_formattedLogs_errorPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    
    ARKTypeLog(ARKLogTypeError, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.errorLogPrefix stringByAppendingString:@"\n"]);
}

- (void)test_formattedLogs_separatorPrefixChangeRespected;
{
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKTypeLog(ARKLogTypeSeparator, @"Separators Rule");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController defaultController].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.separatorLogPrefix stringByAppendingString:@"\n"]);
}

- (void)test_recentErrorLogsAsPlainText_countRespected;
{
    ARKLogController *logController = [ARKLogController defaultController];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKTypeLog(ARKLogTypeError, @"%@", number);
    }];
    
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.logFormatter recentErrorLogsAsPlainText:logController.allLogs count:numberOfRecentErrorLogs];
    
    XCTAssertEqual([recentErrorLogs componentsSeparatedByString:@"\n"].count, numberOfRecentErrorLogs);
}

- (void)test_recentErrorLogsAsPlainText_returnsNilIfNoErrorLogsPresent;
{
    ARKLogController *logController = [ARKLogController defaultController];
    
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.logFormatter recentErrorLogsAsPlainText:logController.allLogs count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
    
    ARKLog(@"This is not an error");
    
    recentErrorLogs = [self.logFormatter recentErrorLogsAsPlainText:logController.allLogs count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
}

#pragma mark - Performance Tests

- (void)test_formattedLogs_performance;
{
    ARKLogController *logController = [ARKLogController defaultController];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < logController.maximumLogCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", number);
    }];
    
    [self measureBlock:^{
        [self.logFormatter formattedLogs:[logController allLogs]];
    }];
}

@end
