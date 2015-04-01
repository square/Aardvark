//
//  ARKURLAdditionsTests.m
//  Aardvark
//
//  Created by Dan Federman on 3/31/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSURL+ARKAdditions.h"


@interface ARKURLAdditionsTests : XCTestCase

@property (nonatomic) NSString *sampleFileName;
@property (nonatomic) NSURL *sampleFileURL;

@end


@implementation ARKURLAdditionsTests

#pragma mark - SetUp

- (void)setUp;
{
    [super setUp];
    
    self.sampleFileName = NSStringFromClass([self class]);
    
    // Create the URL manually so we don't have any side effects.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *archivePath = [applicationSupportDirectory stringByAppendingPathComponent:self.sampleFileName];
    self.sampleFileURL = [NSURL fileURLWithPath:archivePath isDirectory:NO];
    
    // Ensure we start with a clean slate.
    [[NSFileManager defaultManager] removeItemAtPath:[self.sampleFileURL.path stringByDeletingLastPathComponent] error:NULL];
}

#pragma mark - Behavior Tests

- (void)test_fileURLWithApplicationSupportFilename_createsApplicationSupportDirectoryIfItDoesNotExist;
{
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[self.sampleFileURL.path stringByDeletingLastPathComponent]]);
    XCTAssertEqualObjects([NSURL ARK_fileURLWithApplicationSupportFilename:self.sampleFileName], self.sampleFileURL);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[self.sampleFileURL.path stringByDeletingLastPathComponent]]);
}

- (void)test_fileURLWithApplicationSupportFilename_returnsSamePathWhenCalledTwiceSequentially;
{
    XCTAssertEqualObjects([NSURL ARK_fileURLWithApplicationSupportFilename:self.sampleFileName], self.sampleFileURL);
    XCTAssertEqualObjects([NSURL ARK_fileURLWithApplicationSupportFilename:self.sampleFileName], self.sampleFileURL);
}

- (void)test_fileURLWithApplicationSupportFilename_failsIfFileNameComprisesPath;
{
    XCTAssertNil([NSURL ARK_fileURLWithApplicationSupportFilename:[self.sampleFileName stringByAppendingPathComponent:@"PathComponent"]]);
}

- (void)test_fileURLWithApplicationSupportFilename_failsIfFileNameIsEmpty;
{
    XCTAssertNil([NSURL ARK_fileURLWithApplicationSupportFilename:@""]);
}

@end
