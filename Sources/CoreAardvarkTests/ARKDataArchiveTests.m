//
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

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"

#import "ARKLogMessage.h"
#import "NSFileHandle+ARKAdditions.h"
#import "NSURL+ARKAdditions.h"


@interface ARKFaultyUnarchivingObject : NSObject <NSSecureCoding>
@end


@implementation ARKFaultyUnarchivingObject

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    // This is the "faulty" unarchive.
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    // No need to actually archive anything, since we always fail to unarchive.
}

@end


#pragma -


@interface ARKTestDataArchive : ARKDataArchive

@property (nonatomic, readonly) BOOL synchronizedFileHandle;

@end

@implementation ARKTestDataArchive

- (void)_saveArchive_inFileOperationQueue;
{
    _synchronizedFileHandle = YES;
}

@end


#pragma -


@interface ARKDataArchiveTests : XCTestCase

@property (nonatomic) ARKDataArchive *dataArchive;

@end


@implementation ARKDataArchiveTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive.data"];
    
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    
    self.dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:8 trimmedObjectCount:5];
}

- (void)tearDown;
{
    [self.dataArchive saveArchiveAndWait:YES];
    self.dataArchive = nil;
    
    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)test_setUp_providesEmptyArchive;
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertNotNil(unarchivedObjects, @"-[ARKDataArchive readObjectsFromArchiveWithCompletionHandler:] should never return nil!");
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_initWithURL_preservesExistingData;
{
    NSURL *fileURL = self.dataArchive.archiveFileURL;
    
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"One"];
    [self.dataArchive appendArchiveOfObject:@"Two"];
    [self.dataArchive appendArchiveOfObject:@"Three"];
    [self.dataArchive appendArchiveOfObject:@"Four"];
    
    [self.dataArchive saveArchiveAndWait:YES];
    self.dataArchive = nil;
    
    self.dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:10 trimmedObjectCount:5];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"One", @"Two", @"Three", @"Four" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-opened archive didn't have expected objects!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"Five"];
    [self.dataArchive appendArchiveOfObject:@"Six"];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"One", @"Two", @"Three", @"Four", @"Five", @"Six" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-appended archive didn't have expected objects!");
        
        [expectation2 fulfill];
    }];
    
    [self.dataArchive saveArchiveAndWait:YES];
    self.dataArchive = nil;
    
    self.dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:5 trimmedObjectCount:4];
    XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-3", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"Three", @"Four", @"Five", @"Six" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-opened archive didn't trim to new values!");
        
        [expectation3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_appendArchiveOfObject_trimsArchive;
{
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@1];
    [self.dataArchive appendArchiveOfObject:@2];
    [self.dataArchive appendArchiveOfObject:@3];
    [self.dataArchive appendArchiveOfObject:@4];
    [self.dataArchive appendArchiveOfObject:@5];
    [self.dataArchive appendArchiveOfObject:@6];
    [self.dataArchive appendArchiveOfObject:@7];
    [self.dataArchive appendArchiveOfObject:@8];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @1, @2, @3, @4, @5, @6, @7, @8 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected initial maximum number of objects!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@9];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @5, @6, @7, @8, @9 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected initial trimmed objects!");
        
        [expectation2 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@10];
    [self.dataArchive appendArchiveOfObject:@11];
    [self.dataArchive appendArchiveOfObject:@12];
    
    XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-3", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @5, @6, @7, @8, @9, @10, @11, @12 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected second maximum number objects!");
        
        [expectation3 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@13];
    
    XCTestExpectation *expectation4 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-4", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @9, @10, @11, @12, @13 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected second trimmed objects!");
        
        [expectation4 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@14];
    [self.dataArchive appendArchiveOfObject:@15];
    [self.dataArchive appendArchiveOfObject:@16];
    [self.dataArchive appendArchiveOfObject:@17];
    [self.dataArchive appendArchiveOfObject:@18];
    [self.dataArchive appendArchiveOfObject:@19];
    
    XCTestExpectation *expectation5 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-5", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @13, @14, @15, @16, @17, @18, @19 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected final objects!");
        
        [expectation5 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)test_appendArchiveOfObject_trimsCorruptedArchive;
{
    [self.dataArchive appendArchiveOfObject:@1];
    [self.dataArchive appendArchiveOfObject:@2];
    [self.dataArchive appendArchiveOfObject:@3];
    [self.dataArchive appendArchiveOfObject:@4];
    [self.dataArchive appendArchiveOfObject:@5];
    [self.dataArchive appendArchiveOfObject:@6];
    [self.dataArchive appendArchiveOfObject:@7];
    [self.dataArchive appendArchiveOfObject:@8];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @1, @2, @3, @4, @5, @6, @7, @8 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected initial maximum number of objects!");
        
        [expectation1 fulfill];
    }];
    
    // Truncate the file partway into a block length marker (flushing the queue first, since we use the fileHandle directly to corrupt the data).
    [self.dataArchive saveArchiveAndWait:YES];
    [self.dataArchive.fileHandle ARK_seekToDataBlockAtIndex:3];
    [self.dataArchive.fileHandle truncateFileAtOffset:(self.dataArchive.fileHandle.offsetInFile + 2)];
    
    [self.dataArchive appendArchiveOfObject:@9];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @1, @2, @3 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects after trimming a corrupted archive!");
        
        [expectation2 fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)test_initWithURL_detectsCorruptedArchive;
{
    // Populate with data.
    [self.dataArchive appendArchiveOfObject:@[ @1, @2 ]];
    [self.dataArchive appendArchiveOfObject:@[ @3, @4 ]];
    [self.dataArchive appendArchiveOfObject:@[ @5, @6 ]];
    
    // Truncate the file partway into the first block (flushing the queue first, since we use the fileHandle directly to corrupt the data).
    [self.dataArchive saveArchiveAndWait:YES];
    [self.dataArchive.fileHandle truncateFileAtOffset:8];
    
    // Reload from scratch.
    [self.dataArchive saveArchiveAndWait:YES];
    NSURL *fileURL = self.dataArchive.archiveFileURL;
    self.dataArchive = nil;
    self.dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:10 trimmedObjectCount:5];
    
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%@", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSArray class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqualObjects(unarchivedObjects, @[], @"Archive didn't trim invalid data after re-initialization.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_initWithURL_detectsPartiallyCorruptedArchive;
{
    // Populate with data.
    [self.dataArchive appendArchiveOfObject:@[ @1, @2 ]];
    [self.dataArchive appendArchiveOfObject:@[ @3, @4 ]];
    [self.dataArchive appendArchiveOfObject:@[ @5, @6 ]];
    
    // Truncate the file partway into a block length marker (flushing the queue first, since we use the fileHandle directly to corrupt the data).
    [self.dataArchive saveArchiveAndWait:YES];
    [self.dataArchive.fileHandle ARK_seekToDataBlockAtIndex:1];
    [self.dataArchive.fileHandle truncateFileAtOffset:(self.dataArchive.fileHandle.offsetInFile + 2)];
    
    // Reload from scratch.
    [self.dataArchive saveArchiveAndWait:YES];
    NSURL *fileURL = self.dataArchive.archiveFileURL;
    self.dataArchive = nil;
    self.dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:10 trimmedObjectCount:5];
    
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%@", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSArray class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @[ @1, @2 ] ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't truncate invalid data after re-initialization.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_readObjectsFromArchive_excludesFaultyUnarchives;
{
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"First"];
    [self.dataArchive appendArchiveOfObject:@"Second"];
    [self.dataArchive appendArchiveOfObject:@"Third"];
    [self.dataArchive appendArchiveOfObject:[ARKFaultyUnarchivingObject new]];
    [self.dataArchive appendArchiveOfObject:@"Fifth"];
    [self.dataArchive appendArchiveOfObject:@"Sixth"];
    [self.dataArchive appendArchiveOfObject:@"Seventh"];
    [self.dataArchive appendArchiveOfObject:@"Eighth"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"First", @"Second", @"Third", @"Fifth", @"Sixth", @"Seventh", @"Eighth" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects omitted failed unarchiver!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"Ninth"];
    [self.dataArchive appendArchiveOfObject:@"Tenth"];
    [self.dataArchive appendArchiveOfObject:@"Eleventh"];
    [self.dataArchive appendArchiveOfObject:@"Twelfth"];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"Fifth", @"Sixth", @"Seventh", @"Eighth", @"Ninth", @"Tenth", @"Eleventh", @"Twelfth" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects after trimming out failed unarchiver!");
        
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_clearArchiveWithCompletionHandler_removesAllDataFromDisk;
{
    for (NSUInteger i  = 0; i < self.dataArchive.maximumObjectCount; i++) {
        [self.dataArchive appendArchiveOfObject:@(i)];
    }

    [self.dataArchive saveArchiveAndWait:YES];
    
    ARKDataArchive *dataArchive = [[ARKDataArchive alloc] initWithURL:self.dataArchive.archiveFileURL maximumObjectCount:self.dataArchive.maximumObjectCount trimmedObjectCount:self.dataArchive.trimmedObjectCount];
    
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [dataArchive readObjectsFromArchiveOfType:[NSString class] completionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, self.dataArchive.maximumObjectCount);
        
        [dataArchive clearArchiveWithCompletionHandler:^{
            [self.dataArchive readObjectsFromArchiveOfType:[NSNumber class] completionHandler:^(NSArray *unarchivedObjects) {
                XCTAssertEqual(unarchivedObjects.count, 0);
                [expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_clearArchiveWithCompletionHandler_completionHandlerCalledOnMainQueue;
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive clearArchiveWithCompletionHandler:^{
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_saveArchiveWithCompletionHandler_synchronizesFileBeforeCallingCompletionHandler;
{
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive-synchronizes-before-calling-completion.data"];
    ARKTestDataArchive *dataArchive = [[ARKTestDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];

    XCTAssertFalse(dataArchive.synchronizedFileHandle);

    XCTestExpectation *expectation = [self expectationWithDescription:@"call completion"];
    [dataArchive saveArchiveWithCompletionHandler:^{
        XCTAssertTrue(dataArchive.synchronizedFileHandle);
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5];
}

#pragma mark - Performance Tests

- (void)test_appendArchiveOfObject_performance;
{
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive-performance.data"];
    ARKDataArchive *dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < dataArchive.maximumObjectCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Start fresh.
        [dataArchive.fileHandle truncateFileAtOffset:0];
        [dataArchive saveArchiveAndWait:YES];

        // Concurrently add all of the objects.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            [dataArchive appendArchiveOfObject:number];
        }];
        
        [dataArchive waitUntilAllOperationsAreFinished];
    }];
}

- (void)test_saveArchive_performance;
{
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive-performance.data"];
    ARKDataArchive *dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < dataArchive.maximumObjectCount; i++) {
        [numbers addObject:@(i)];
    }
    
    [self measureBlock:^{
        // Start fresh.
        [dataArchive.fileHandle truncateFileAtOffset:0];
        [dataArchive saveArchiveAndWait:YES];
        
        // Concurrently add all of the objects.
        [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
            [dataArchive appendArchiveOfObject:number];
        }];
        
        [dataArchive saveArchiveAndWait:YES];
    }];
}

- (void)test_appendLogsAndSave_performance;
{
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive-performance.data"];
    ARKDataArchive *dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];
    
    NSMutableArray *logMessages = [NSMutableArray new];
    for (NSUInteger i  = 0; i < dataArchive.maximumObjectCount; i++) {
        [logMessages addObject:[[ARKLogMessage alloc] initWithText:[NSString stringWithFormat:@"%@", @(i)] image:nil type:ARKLogTypeDefault parameters:@{} userInfo:nil]];
    }
    
    [self measureBlock:^{
        // Start fresh.
        [dataArchive.fileHandle truncateFileAtOffset:0];
        [dataArchive saveArchiveAndWait:YES];
        
        // Concurrently add all of the logs.
        [logMessages enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(ARKLogMessage *logMessage, NSUInteger idx, BOOL *stop) {
            [dataArchive appendArchiveOfObject:logMessage];
        }];
        
        [dataArchive saveArchiveAndWait:YES];
    }];
}

- (void)test_initWithURL_performance;
{
    // Start fresh.
    NSURL *fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"archive-performance.data"];
    ARKDataArchive *dataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];
    [dataArchive.fileHandle truncateFileAtOffset:0];
    [dataArchive saveArchiveAndWait:YES];
    
    NSMutableArray *numbers = [NSMutableArray new];
    for (NSUInteger i  = 0; i < dataArchive.maximumObjectCount; i++) {
        [numbers addObject:@(i)];
    }
    
    // Concurrently add all of the objects.
    [numbers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        [dataArchive appendArchiveOfObject:number];
    }];
    
    [dataArchive saveArchiveAndWait:YES];
    
    [self measureBlock:^{
        ARKDataArchive *performanceTestDataArchive = [[ARKDataArchive alloc] initWithURL:fileURL maximumObjectCount:500 trimmedObjectCount:500];
        [performanceTestDataArchive waitUntilAllOperationsAreFinished];
    }];
}

@end
