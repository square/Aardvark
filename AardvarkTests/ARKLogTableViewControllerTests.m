//
//  ARKLogTableViewControllerTests.m
//  Aardvark
//
//  Created by Dan Federman on 12/15/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKLogTableViewController.h"
#import "ARKLogTableViewController_Testing.h"

#import "ARKDefaultLogFormatter.h"
#import "ARKLogDistributor.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"


@class ARKTimestampLogMessage;


@interface ARKFakeLogMessage : ARKLogMessage

- (instancetype)initWithDate:(NSDate *)date;

@end


@implementation ARKFakeLogMessage

@synthesize creationDate = _creationDate;

#pragma mark - Initialization

- (instancetype)initWithDate:(NSDate *)date;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    _creationDate = date;
    
    return self;
}

#pragma mark - NSObject

- (NSString *)description;
{
    NSString *dateString = [NSDateFormatter localizedStringFromDate:self.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    return [NSString stringWithFormat:@"[%@] Fake Log", dateString];
}

@end


@interface ARKLogTableViewControllerTests : XCTestCase

@property (nonatomic, strong, readwrite) ARKLogTableViewController *logTableViewController;
@property (nonatomic, strong, readwrite) ARKLogStore *logStore;
@property (nonatomic, strong, readwrite) ARKLogDistributor *logDistributor;

@end


@implementation ARKLogTableViewControllerTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.logStore = [ARKLogStore new];
    self.logDistributor = [ARKLogDistributor new];
    self.logStore.logDistributor = self.logDistributor;
    self.logTableViewController = [[ARKLogTableViewController alloc] initWithLogStore:self.logStore logFormatter:[ARKDefaultLogFormatter new]];
}

#pragma mark - Behavior Tests



- (void)test_minutesBetweenTimestamps_insertsTimestampsBetweenLogs;
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
        XCTAssertEqual([self.logTableViewController.logMessages[1] creationDate], threeMinutesFiveSecondsAgo);
        
        XCTAssertEqual([self.logTableViewController.logMessages[2] class], [ARKFakeLogMessage class]);
        XCTAssertEqual([self.logTableViewController.logMessages[2] creationDate], twoMinutesFiftyFiveSecondsAgo);
        
        XCTAssertEqual([self.logTableViewController.logMessages[3] class], [ARKTimestampLogMessage class]);
        
        XCTAssertEqual([self.logTableViewController.logMessages[4] class], [ARKFakeLogMessage class]);
        XCTAssertEqual([self.logTableViewController.logMessages[4] creationDate], now);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
