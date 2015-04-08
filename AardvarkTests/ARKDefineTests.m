//
//  ARKDefineTests.m
//  Aardvark
//
//  Created by Dan Federman on 12/2/14.
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

#import <XCTest/XCTest.h>

#import "AardvarkDefines.h"


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
