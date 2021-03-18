//
//  Copyright 2014 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import CoreAardvark;
@import XCTest;

#import "ARKDefaultLogFormatter.h"

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"
#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"
#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"


@interface ARKDefaultLogFormatterTests : XCTestCase

@property (nonatomic) ARKLogDistributor *defaultLogDistributor;
@property (nonatomic) ARKDefaultLogFormatter *logFormatter;
@property (nonatomic, weak) ARKLogStore *logStore;

@end


@implementation ARKDefaultLogFormatterTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.defaultLogDistributor = [ARKLogDistributor defaultDistributor];
    
    self.logFormatter = [ARKDefaultLogFormatter new];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromClass([self class])];
    
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    self.logStore = logStore;
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Behavior Tests

- (void)test_formattedLogMessage_errorLogLineCount;
{
    ARKLogWithType(ARKLogTypeError, nil, @"Fake Error Log");
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 2, @"Logging an error should create two lines of formatted logs");
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_separatorLogLineCount;
{
    ARKLogWithType(ARKLogTypeSeparator, nil, @"Separators Rule");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 2, @"Logging a separator should create two lines of formatted logs");
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_defaultLogLineCount;
{
    ARKLog(@"Something Happened");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 1, @"Logging a default log should create one line of formatted logs");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_errorLogContent;
{
    NSString *errorLog = @"Fake Error Log";
    ARKLogWithType(ARKLogTypeError, nil, @"%@", errorLog);
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
        XCTAssertEqualObjects(splitLog.lastObject, [logMessages.firstObject description]);
        XCTAssertEqual(splitLog.count, 2);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_separatorLogContent;
{
    NSString *separatorLog = @"Separators Rule";
    ARKLogWithType(ARKLogTypeSeparator, nil, @"%@", separatorLog);
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
        XCTAssertEqualObjects(splitLog.lastObject, [logMessages.firstObject description]);
        XCTAssertEqual(splitLog.count, 2);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_defaultLogContent;
{
    NSString *log = @"Something Happened";
    ARKLog(@"%@", log);
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqualObjects(splitLog.firstObject, [logMessages.firstObject description]);
        XCTAssertEqual(splitLog.count, 1);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_errorPrefixChangeRespected;
{
    self.logFormatter.errorLogPrefix = @"Error";
    
    ARKLogWithType(ARKLogTypeError, nil, @"Fake Error Log");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.errorLogPrefix);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_separatorPrefixChangeRespected;
{
    self.logFormatter.separatorLogPrefix = @"New Thing";
    
    ARKLogWithType(ARKLogTypeSeparator, nil, @"Separators Rule");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqualObjects(splitLog.firstObject, self.logFormatter.separatorLogPrefix);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_errorPrefixOnSameLineIfLogTextIsEmpty;
{
    ARKLogWithType(ARKLogTypeError, nil, @"");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 1);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_separatorPrefixOnSameLineIfLogTextIsEmpty;
{
    ARKLogWithType(ARKLogTypeSeparator, nil, @"");
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);
        
        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 1);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_parameters;
{
    ARKLogWithParameters(@{@"Hello": @"World", @"Foo": @"Bar"}, @"Test message");

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);

        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        XCTAssertEqual(splitLog.count, 3);

        if (splitLog.count == 3) {
            XCTAssertEqualObjects([splitLog objectAtIndex:1], @" - Foo: Bar");
            XCTAssertEqualObjects([splitLog objectAtIndex:2], @" - Hello: World");
        }

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_formattedLogMessage_multilineParameter;
{
    ARKLogWithParameters(@{@"Some Key": @"This is a\nparameter value that\nspans multiple lines"}, @"Test message");

    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(logMessages.count, 1);

        ARKLogMessage *const firstLogMessage = logMessages.firstObject;
        NSString *const formattedSingleLog = [self.logFormatter formattedLogMessage:firstLogMessage];
        NSArray<NSString *> *const splitLog = [formattedSingleLog componentsSeparatedByString:@"\n"];
        NSString *const formattedParameters = [[splitLog subarrayWithRange:NSMakeRange(1, splitLog.count - 1)] componentsJoinedByString:@"\n"];

        NSString *const expectedFormattedParameters = @" - Some Key: This is a\n"
                                                       "             parameter value that\n"
                                                       "             spans multiple lines";

        XCTAssert([formattedParameters isEqualToString:expectedFormattedParameters]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
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
        XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
        [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
            for (ARKLogMessage *logMessage in logMessages) {
                [self.logFormatter formattedLogMessage:logMessage];
            }
            
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
    }];
}

@end
