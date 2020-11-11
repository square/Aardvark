//
//  ARKExceptionLoggingTests.m
//  Aardvark
//
//  Created by Nick Entin on 9/28/18.
//  Copyright 2018 Square, Inc.
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

#import "ARKExceptionLogging.h"
#import "ARKExceptionLogging_Testing.h"
#import "ARKLogDistributor.h"
#import "ARKLogStore.h"


@interface ARKExceptionLoggingTests : XCTestCase

@property (nonatomic, strong) ARKLogDistributor *logDistributor;
@property (nonatomic, weak) ARKLogStore *logStore;

@end


XCTestExpectation *_Nullable ARKTestUncaughtExceptionHandlerExpectation = nil;

void ARKTestUncaughtExceptionHandler(NSException *_Nonnull exception)
{
    [ARKTestUncaughtExceptionHandlerExpectation fulfill];
}


NSUncaughtExceptionHandler *_Nullable ARKTestGetUncaughtExceptionHandlerValue = NULL;

NSUncaughtExceptionHandler *_Nullable ARKTestGetUncaughtExceptionHandler(void)
{
    return ARKTestGetUncaughtExceptionHandlerValue;
}


XCTestExpectation *_Nullable ARKTestSetUncaughtExceptionHandlerExpectation = nil;
XCTestExpectation *_Nullable ARKTestSetPreviousUncaughtExceptionHandlerExpectation = nil;
NSInteger ARKTestSetUncaughtExceptionHandlerExecutionCount = 0;

void ARKTestSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *_Nullable uncaughtExceptionHandler)
{
    ARKTestSetUncaughtExceptionHandlerExecutionCount += 1;
    
    if (ARKTestSetUncaughtExceptionHandlerExpectation != nil && uncaughtExceptionHandler != ARKTestGetUncaughtExceptionHandlerValue) {
        [ARKTestSetUncaughtExceptionHandlerExpectation fulfill];
        
    } else if (ARKTestSetPreviousUncaughtExceptionHandlerExpectation != nil && uncaughtExceptionHandler == ARKTestGetUncaughtExceptionHandlerValue) {
        [ARKTestSetPreviousUncaughtExceptionHandlerExpectation fulfill];
    }
}


@implementation ARKExceptionLoggingTests

- (void)setUp {
    [super setUp];
    
    self.logDistributor = [ARKLogDistributor new];
    
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:NSStringFromClass([self class])];
    
    self.logDistributor.defaultLogStore = logStore;
    self.logStore = logStore;
    
    ARKGetUncaughtExceptionHandler = ARKTestGetUncaughtExceptionHandler;
    ARKTestGetUncaughtExceptionHandlerValue = NULL;
    
    ARKSetUncaughtExceptionHandler = ARKTestSetUncaughtExceptionHandler;
    ARKTestSetUncaughtExceptionHandlerExpectation = nil;
    ARKTestSetPreviousUncaughtExceptionHandlerExpectation = nil;
    ARKTestSetUncaughtExceptionHandlerExecutionCount = 0;
    
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)tearDown {
    XCTestExpectation *const expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.logStore clearLogsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    ARKPreviousUncaughtExceptionHandler = NULL;
    ARKUncaughtExceptionLogDistributors = nil;
    
    ARKGetUncaughtExceptionHandler = NSGetUncaughtExceptionHandler;
    ARKTestGetUncaughtExceptionHandlerValue = NULL;
    
    ARKSetUncaughtExceptionHandler = NSSetUncaughtExceptionHandler;
    ARKTestSetUncaughtExceptionHandlerExpectation = nil;
    ARKTestSetPreviousUncaughtExceptionHandlerExpectation = nil;
    ARKTestSetUncaughtExceptionHandlerExecutionCount = 0;
    
    [super tearDown];
}

#pragma mark - Tests

- (void)test_setsUncaughtExceptionHandler;
{
    ARKTestSetUncaughtExceptionHandlerExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_cleansUpStateOnDisable;
{
    ARKTestGetUncaughtExceptionHandlerValue = ARKTestUncaughtExceptionHandler;
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    
    ARKTestSetPreviousUncaughtExceptionHandlerExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    ARKDisableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqual(ARKPreviousUncaughtExceptionHandler, NULL);
    XCTAssertNil(ARKUncaughtExceptionLogDistributors);
}

- (void)test_callsPreviousUncaughtExceptionHandler;
{
    ARKTestGetUncaughtExceptionHandlerValue = ARKTestUncaughtExceptionHandler;
    
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    
    NSException *const exception = [NSException exceptionWithName:NSGenericException reason:@"Test Exception" userInfo:nil];
    
    ARKTestUncaughtExceptionHandlerExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    ARKHandleUncaughtException(exception);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_restoresPreviousUncaughtExceptionHandler;
{
    ARKTestGetUncaughtExceptionHandlerValue = ARKTestUncaughtExceptionHandler;
    
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    
    ARKTestSetPreviousUncaughtExceptionHandlerExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    ARKDisableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_multipleLogDistributors_onlySetsOnce;
{
    ARKLogDistributor *const secondLogDistributor = [ARKLogDistributor new];
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:[NSString stringWithFormat:@"%@-2", NSStringFromClass([self class])]];
    secondLogDistributor.defaultLogStore = logStore;
    
    ARKTestSetUncaughtExceptionHandlerExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    ARKEnableLogOnUncaughtExceptionToLogDistributor(secondLogDistributor);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertEqual(ARKTestSetUncaughtExceptionHandlerExecutionCount, 1);
}

- (void)test_multipleLogDistributors_onlyCleansUpAfterFinalDistributor;
{
    ARKTestGetUncaughtExceptionHandlerValue = ARKTestUncaughtExceptionHandler;
    
    ARKLogDistributor *const secondLogDistributor = [ARKLogDistributor new];
    ARKLogStore *const logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:[NSString stringWithFormat:@"%@-3", NSStringFromClass([self class])]];
    secondLogDistributor.defaultLogStore = logStore;
    
    ARKEnableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    ARKEnableLogOnUncaughtExceptionToLogDistributor(secondLogDistributor);
    ARKDisableLogOnUncaughtExceptionToLogDistributor(self.logDistributor);
    
    XCTAssert([ARKUncaughtExceptionLogDistributors isEqualToArray:@[ secondLogDistributor ]]);
    XCTAssert(ARKPreviousUncaughtExceptionHandler == ARKTestUncaughtExceptionHandler);
}

@end
