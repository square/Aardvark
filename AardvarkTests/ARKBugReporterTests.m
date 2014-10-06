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

#pragma mark - Tests

- (void)testSetupBugReporter;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    [Aardvark setupBugReportingWithReporter:bugReporter];
    
    __weak ARKEmailBugReporter *weakBugReporter = bugReporter;
    bugReporter = nil;
    
    XCTAssertNotNil(weakBugReporter);
}

@end
