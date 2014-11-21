//
//  ARKEmailBugReporterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/20/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReporter_Testing.h"

#import "ARKLogDistributor.h"
#import "ARKLogStore.h"


@interface ARKEmailBugReporterTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic, strong, readwrite) ARKEmailBugReporter *bugReporter;
@property (nonatomic, weak, readwrite) ARKLogStore *logStore;

@end


@implementation ARKEmailBugReporterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    self.bugReporter = [ARKEmailBugReporter new];
    
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

- (void)test_recentErrorLogMessagesAsPlainText_countRespected;
{
    NSMutableArray *numbers = [NSMutableArray new];
    for (int i = 0; i < self.logStore.maximumLogMessageCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the logs.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        ARKLogWithType(ARKLogTypeError, nil, @"%@", number);
    }];
    
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:self.logStore.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqual([recentErrorLogs componentsSeparatedByString:@"\n"].count, numberOfRecentErrorLogs);
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfNoErrorLogsPresent;
{
    const NSUInteger numberOfRecentErrorLogs = 5;
    NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:self.logStore.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
    
    ARKLog(@"This is not an error");
    
    recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:self.logStore.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
}

- (void)test_recentErrorLogMessagesAsPlainText_returnsNilIfRecentErrorLogsIsZero;
{
    const NSUInteger numberOfRecentErrorLogs = 0;
    NSString *recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:self.logStore.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
    
    ARKLog(@"This is not an error");
    
    recentErrorLogs = [self.bugReporter _recentErrorLogMessagesAsPlainText:self.logStore.allLogMessages count:numberOfRecentErrorLogs];
    
    XCTAssertEqualObjects(recentErrorLogs, nil);
}

@end
