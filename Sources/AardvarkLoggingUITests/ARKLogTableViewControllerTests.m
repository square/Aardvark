//
//  ARKLogTableViewControllerTests.m
//  Aardvark
//
//  Created by Dan Federman on 12/15/14.
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

@import XCTest;

#import "ARKLogTableViewController.h"
#import "ARKLogTableViewController_Testing.h"

#import "AardvarkDefines.h"
#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKLogDistributor.h"
#import "ARKLogDistributor_Testing.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"
#import "ARKLogStore_Testing.h"


@class ARKTimestampLogMessage;


@interface ARKFakeLogMessage : ARKLogMessage

- (instancetype)initWithDate:(NSDate *)date;

@end


@implementation ARKFakeLogMessage

#pragma mark - Initialization

- (instancetype)initWithDate:(NSDate *)date;
{
    self = [super initWithText:@"Fake Log" image:nil type:ARKLogTypeDefault userInfo:nil date:date];
    if (!self) {
        return nil;
    }
    
    return self;
}

@end


@interface ARKLogTableViewControllerTests : XCTestCase

@property (nonatomic) ARKLogTableViewController *logTableViewController;
@property (nonatomic, weak) ARKLogStore *logStore;
@property (nonatomic) ARKLogDistributor *logDistributor;

@end


@implementation ARKLogTableViewControllerTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromSelector(_cmd)];
    
    self.logDistributor = [ARKLogDistributor new];
    [self.logDistributor addLogObserver:logStore];
    self.logTableViewController = [[ARKLogTableViewController alloc] initWithLogStore:logStore logFormatter:[ARKDefaultLogFormatter new]];
    
    self.logStore = logStore;
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
}

#pragma mark - Behavior Tests

- (void)test_logMessagesWithMinuteSeparators_insertsTimestampsBetweenLogs;
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    NSDate *now = [NSDate date];
    NSDate *threeMinutesFiveSecondsAgo = [NSDate dateWithTimeInterval:(NSTimeInterval)-185.0 sinceDate:now];
    NSDate *twoMinutesFiftyFiveSecondsAgo = [NSDate dateWithTimeInterval:(NSTimeInterval)-175.0 sinceDate:now];
    
    [self.logStore observeLogMessage:[[ARKFakeLogMessage alloc] initWithDate:threeMinutesFiveSecondsAgo]];
    [self.logStore observeLogMessage:[[ARKFakeLogMessage alloc] initWithDate:twoMinutesFiftyFiveSecondsAgo]];
    [self.logStore observeLogMessage:[[ARKFakeLogMessage alloc] initWithDate:now]];
    
    [self.logTableViewController _reloadLogs];
    
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        XCTAssertEqual(self.logTableViewController.logMessages.count, 5);
        XCTAssertEqual([self.logTableViewController.logMessages[0] class], [ARKTimestampLogMessage class]);
        
        XCTAssertEqual([self.logTableViewController.logMessages[1] class], [ARKFakeLogMessage class]);
        XCTAssertEqualObjects([self.logTableViewController.logMessages[1] date], threeMinutesFiveSecondsAgo);
        
        XCTAssertEqual([self.logTableViewController.logMessages[2] class], [ARKFakeLogMessage class]);
        XCTAssertEqualObjects([self.logTableViewController.logMessages[2] date], twoMinutesFiftyFiveSecondsAgo);
        
        XCTAssertEqual([self.logTableViewController.logMessages[3] class], [ARKTimestampLogMessage class]);
        
        XCTAssertEqual([self.logTableViewController.logMessages[4] class], [ARKFakeLogMessage class]);
        XCTAssertEqualObjects([self.logTableViewController.logMessages[4] date], now);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
