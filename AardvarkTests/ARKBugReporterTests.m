//
//  ARKBugReporterTests.m
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKEmailBugReporter.h"


@interface ARKBugReporterTests : XCTestCase
@end


@implementation ARKBugReporterTests

#pragma mark - Behavior Tests

- (void)test_bugReporter_setupReporterRetainedByAardvark;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    [Aardvark enableBugReportingWithReporter:bugReporter];
    
    __weak ARKEmailBugReporter *weakBugReporter = bugReporter;
    bugReporter = nil;
    
    XCTAssertNotNil(weakBugReporter);
}

@end
