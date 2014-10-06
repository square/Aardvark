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
    
    self.logFormatter = [ARKDefaultLogFormatter new];
}

- (void)tearDown;
{
    [[ARKLogController sharedInstance] clearLocalLogs];

    [super tearDown];
}

#pragma mark - Tests

- (void)testFormattedLogLength;
{
    ARKTypeLog(ARKLogTypeError, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging an error should create two lines of formatted logs");
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    ARKTypeLog(ARKLogTypeSeparator, @"Separators Rule");
    formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 2, @"Logging a separator should create two lines of formatted logs");
    
    [[ARKLogController sharedInstance] clearLocalLogs];

    ARKLog(@"Something Happened");
    formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqual(formattedSingleLog.count, 1, @"Logging a default log should create one line of formatted logs");
}

- (void)testFormattedLogExpectedOutput;
{
    NSString *errorLog = @"Fake Error Log";
    ARKTypeLog(ARKLogTypeError, @"%@", errorLog);
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController sharedInstance].logs.firstObject description] stringByAppendingString:@"\n"]);
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    NSString *separatorLog = @"Separators Rule";
    ARKTypeLog(ARKLogTypeSeparator, @"%@", separatorLog);
    formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController sharedInstance].logs.firstObject description] stringByAppendingString:@"\n"]);
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.lastObject, [[[ARKLogController sharedInstance].logs.firstObject description] stringByAppendingString:@"\n"]);
    XCTAssertEqualObjects(formattedSingleLog.firstObject, formattedSingleLog.lastObject);
}

- (void)testPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKTypeLog(ARKLogTypeError, @"Fake Error Log");
    NSArray *formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.errorLogPrefix stringByAppendingString:@"\n"]);
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    ARKTypeLog(ARKLogTypeSeparator, @"Separators Rule");
    formattedSingleLog = [self.logFormatter formattedLogs:[ARKLogController sharedInstance].allLogs];
    XCTAssertEqualObjects(formattedSingleLog.firstObject, [self.logFormatter.separatorLogPrefix stringByAppendingString:@"\n"]);
}

- (void)testFormattedLogsAsData;
{
    ARKLog(@"Test Log 1");
    ARKLog(@"Test Log 2");
    ARKLog(@"Test Log 3");
    
    NSData *formattedLogData = [self.logFormatter formattedLogsAsData:[ARKLogController sharedInstance].allLogs];
    NSString *formattedLogs = [self.logFormatter formattedLogsAsPlainText:[ARKLogController sharedInstance].allLogs];
    
    XCTAssertEqualObjects([[NSString alloc] initWithData:formattedLogData encoding:NSUTF8StringEncoding], formattedLogs);
}

- (void)testRecentErrorLogs;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
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

#pragma mark - Performance Tests

- (void)testLogFormattingPerformance;
{
    ARKLogController *logController = [ARKLogController sharedInstance];
    
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
