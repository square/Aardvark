//
//  ARKURLAdditionsTests.m
//  Aardvark
//
//  Created by Dan Federman on 3/31/15.
//  Copyright 2015 Square, Inc.
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
    NSArray *const paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *const applicationSupportDirectory = paths.firstObject;
    NSString *const archivePath = [applicationSupportDirectory stringByAppendingPathComponent:self.sampleFileName];
    self.sampleFileURL = [NSURL fileURLWithPath:archivePath isDirectory:NO];
    
    // Ensure we start with a clean slate.
    NSString *const filePathToDelete = [self.sampleFileURL.path stringByDeletingLastPathComponent];
    if (filePathToDelete != nil) {
        [[NSFileManager defaultManager] removeItemAtPath:filePathToDelete error:NULL];
    }
}

#pragma mark - Behavior Tests

- (void)test_fileURLWithApplicationSupportFilename_createsApplicationSupportDirectoryIfItDoesNotExist;
{
    NSString *const filePathToDelete = [self.sampleFileURL.path stringByDeletingLastPathComponent];
    XCTAssertNotNil(filePathToDelete);
    
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePathToDelete]);
    XCTAssertEqualObjects([NSURL ARK_fileURLWithApplicationSupportFilename:self.sampleFileName], self.sampleFileURL);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePathToDelete]);
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
