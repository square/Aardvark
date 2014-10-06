//
//  ARKLogControllerTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKLogController.h"


@interface ARKLogControllerTests : XCTestCase
@end


@implementation ARKLogControllerTests

- (void)tearDown;
{
    [[ARKLogController sharedInstance] clearLocalLogs];
    [super tearDown];
}

#pragma mark - Clearing Logs Test

- (void)testClearLogs;
{
    for (int i = 0; i < 100; i++) {
        ARKLog(@"Log %@", @(i));
    }
    
    [[ARKLogController sharedInstance] clearLocalLogs];
    
    XCTAssertTrue([ARKLogController sharedInstance].allLogs.count == 0, @"Local logs have count of %@ after clearing!", @([ARKLogController sharedInstance].allLogs.count));
}

#pragma mark - Synchronization Tests

- (void)testSynchronization;
{
    NSMutableArray *UUIDs = [NSMutableArray new];
    for (int i = 0; i < 1000; i++) {
        [UUIDs addObject:[NSUUID UUID]];
    }
    
    [UUIDs enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSUUID *UUID, NSUInteger idx, BOOL *stop) {
        ARKLog(@"%@", UUID.UUIDString);
    }];
    
    XCTAssertTrue([ARKLogController sharedInstance].allLogs.count == UUIDs.count, @"Local logs have count of %@ after concurrently adding %@ logs!", @([ARKLogController sharedInstance].allLogs.count), @(UUIDs.count));
}

@end
