//
//  ARKDefineTests.m
//  Aardvark
//
//  Created by Dan Federman on 12/2/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface ARKDefineTests : XCTestCase
@end


@implementation ARKDefineTests

#pragma mark - Behavior Tests

- (void)test_ARKCheckCondition_doesNothingIfConditionIsMet;
{
    XCTAssertTrue([self _testCheckCondition:YES]);
}

- (void)test_ARKCheckCondition_returnsCheckConditionValueIfConditionIsNotMet;
{
    XCTAssertFalse([self _testCheckCondition:NO]);
}

#pragma mark - Private Methods

- (BOOL)_testCheckCondition:(BOOL)shouldPass;
{
    ARKCheckCondition(shouldPass, NO, @"Told to not pass check condition!");
    
    return YES;
}

@end
