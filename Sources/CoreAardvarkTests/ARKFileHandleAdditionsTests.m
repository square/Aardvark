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

#import "NSFileHandle+ARKAdditions.h"

#import "NSURL+ARKAdditions.h"


@interface ARKFileHandle : NSFileHandle

@property (nonatomic, copy) dispatch_block_t writeDataBlock;

@end

@implementation ARKFileHandle

- (void)writeData:(NSData *)data;
{
    if (self.writeDataBlock != nil) {
        self.writeDataBlock();
    } else {
        [super writeData:data];
    }
}

@end

@interface ARKFileHandleAdditionsTests : XCTestCase

@property (nonatomic) NSFileHandle *fileHandle;

@property (nonatomic, copy) NSURL *fileURL;

@property (nonatomic) NSData *data_4;
@property (nonatomic) NSData *block_4;

@property (nonatomic) NSData *data_6;
@property (nonatomic) NSData *block_6;

@property (nonatomic) NSData *data_7;
@property (nonatomic) NSData *block_7;

@property (nonatomic) NSData *data_9;
@property (nonatomic) NSData *block_9;

@end


@implementation ARKFileHandleAdditionsTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    if (self.fileURL == nil) {
        self.fileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:@"FileHandleAdditionsTests.data"];
        
        // Create sample data blocks. The lengths of each block are numbers that don't occur in the contents.
        uint8_t bytes_4[] = { 1, 1, 2, 3 };
        uint8_t bytes_6[] = { 5, 8, 13, 21, 34, 55 };
        uint8_t bytes_7[] = { 53, 59, 61, 67, 71, 73, 79 };
        uint8_t bytes_9[] = { 83, 89, 101, 103, 107, 109, 113, 127, 131 };
        
        // The data_x objects are the input, and the dataWithLength_x objects are the expected contents of the file.
        self.data_4 = [[NSData alloc] initWithBytes:bytes_4 length:4];
        self.block_4 = [self _blockForData:self.data_4];
        
        self.data_6 = [[NSData alloc] initWithBytes:bytes_6 length:6];
        self.block_6 = [self _blockForData:self.data_6];
        
        self.data_7 = [[NSData alloc] initWithBytes:bytes_7 length:7];
        self.block_7 = [self _blockForData:self.data_7];
        
        self.data_9 = [[NSData alloc] initWithBytes:bytes_9 length:9];
        self.block_9 = [self _blockForData:self.data_9];
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:NULL];
    NSString *const filePath = self.fileURL.path;
    if (filePath.length > 0) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        
        self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    }
}

- (void)tearDown;
{
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    
    [NSFileHandle ARK_setPreventWritesAfterException:NO];

    [super tearDown];
}

#pragma mark - Behavior Tests

- (void)_assertFileContentsMatchDataList:(NSArray *)dataList failureMessage:(NSString *)failureMessage;
{
    NSMutableData *concatenatedData = [NSMutableData new];
    for (NSData *data in dataList) {
        [concatenatedData appendData:data];
    }
    
    [self.fileHandle synchronizeFile];
    NSData *fileData = [NSData dataWithContentsOfURL:self.fileURL];
    XCTAssertEqualObjects(fileData, concatenatedData, @"%@", failureMessage);
}

- (void)test_writeDataBlock;
{
    // Check that the file starts empty.
    [self _assertFileContentsMatchDataList:@[] failureMessage:@"File should start out empty."];
    
    // Write data to empty file.
    [self.fileHandle ARK_writeDataBlock:self.data_6];
    [self _assertFileContentsMatchDataList:@[ self.block_6 ] failureMessage:@"Failed to write block to empty file."];
    
    // Append data to non-empty file.
    [self.fileHandle ARK_writeDataBlock:self.data_7];
    [self _assertFileContentsMatchDataList:@[ self.block_6, self.block_7 ] failureMessage:@"Failed to write block at end of file."];
    
    // Over-write data in file (note that 9+4 = 6+7 so the contents line up).
    [self.fileHandle ARK_writeDataBlock:self.data_7];
    [self.fileHandle seekToFileOffset:0];
    [self.fileHandle ARK_writeDataBlock:self.data_9];
    [self.fileHandle ARK_writeDataBlock:self.data_4];
    [self _assertFileContentsMatchDataList:@[ self.block_9, self.block_4, self.block_7 ] failureMessage:@"Failed to over-write data in file."];
    
    // Write empty-length data.    
    [self.fileHandle ARK_writeDataBlock:[NSData data]];
    [self _assertFileContentsMatchDataList:@[ self.block_9, self.block_4, self.block_7 ] failureMessage:@"Writing empty data shouldn't change the file."];
}

- (void)test_appendDataBlock;
{
    // Check that the file starts empty.
    [self _assertFileContentsMatchDataList:@[] failureMessage:@"File should start out empty."];
    
    // Append to empty file.
    [self.fileHandle ARK_appendDataBlock:self.data_6];
    [self _assertFileContentsMatchDataList:@[ self.block_6 ] failureMessage:@"Failed to append block to empty file."];
    
    // Seek to beginning and append.
    [self.fileHandle seekToFileOffset:0];
    [self.fileHandle ARK_appendDataBlock:self.data_7];
    [self _assertFileContentsMatchDataList:@[ self.block_6, self.block_7 ] failureMessage:@"Failed to append block after seeking to beginning of file."];
    
    // Seek to middle and append.
    [self.fileHandle seekToFileOffset:10];
    [self.fileHandle ARK_appendDataBlock:self.data_9];
    [self _assertFileContentsMatchDataList:@[ self.block_6, self.block_7, self.block_9 ] failureMessage:@"Failed to append block after seeking to middle of file."];
    
    // Seek to end and append.
    (void)[self.fileHandle seekToEndOfFile];
    [self.fileHandle ARK_appendDataBlock:self.data_4];
    [self _assertFileContentsMatchDataList:@[ self.block_6, self.block_7, self.block_9, self.block_4 ] failureMessage:@"Failed to append to block after seeking to end of file."];
    
    // Append empty data.
    [self.fileHandle ARK_appendDataBlock:[NSData data]];
    [self _assertFileContentsMatchDataList:@[ self.block_6, self.block_7, self.block_9, self.block_4 ] failureMessage:@"Appending empty data shouldn't change the file."];
}

- (void)_assert_seekToDataBlockAtIndex:(NSUInteger)index seeksToIndex:(NSUInteger)expectedIndex atFileOffset:(unsigned long long)expectedFileOffset;
{
    NSUInteger seekIndex = [self.fileHandle ARK_seekToDataBlockAtIndex:index];
    unsigned long long seekOffset = self.fileHandle.offsetInFile;
    
    XCTAssertEqual(seekIndex, expectedIndex, @"seekToDataBlockAtIndex:%@ didn't seek to expected index.", @(index));
    XCTAssertEqual(seekOffset, expectedFileOffset, "seekToDataBlockAtIndex:%@ didn't seek to expected file offset.", @(index));
}

- (void)test_seekToDataBlockAtIndex;
{
    XCTAssertEqual(self.fileHandle.offsetInFile, 0, @"Offset should start out at 0.");
    
    // Define these up front for convenience.
    unsigned long long offset0 = 0;
    unsigned long long offset1 = offset0 + self.block_4.length;
    unsigned long long offset2 = offset1 + self.block_7.length;
    unsigned long long offset3 = offset2 + self.block_6.length;
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:0 atFileOffset:offset0];
    
    [self.fileHandle ARK_appendDataBlock:self.data_4];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:2 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:1 atFileOffset:offset1];
    
    [self.fileHandle ARK_appendDataBlock:self.data_7];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:2 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:3 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:2 atFileOffset:offset2];
    
    [self.fileHandle ARK_appendDataBlock:self.data_6];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:2 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:3 seeksToIndex:3 atFileOffset:offset3];
    [self _assert_seekToDataBlockAtIndex:4 seeksToIndex:3 atFileOffset:offset3];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:3 atFileOffset:offset3];
}

- (void)test_seekToDataBlockAtIndex_detectsCorruptedData;
{
    // Define these up front for convenience.
    unsigned long long offset0 = 0;
    unsigned long long offset1 = offset0 + self.block_7.length;
    unsigned long long offset2 = offset1 + self.block_9.length;
    unsigned long long offset3 = offset2 + self.block_4.length;
    
    [self.fileHandle ARK_appendDataBlock:self.data_7];
    [self.fileHandle ARK_appendDataBlock:self.data_9];
    [self.fileHandle ARK_appendDataBlock:self.data_4];
    
    // Truncate part of the last data block.
    [self.fileHandle truncateFileAtOffset:(offset3 - 3)];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:2 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:3 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:4 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:2 atFileOffset:offset2];
    
    // Truncate part of the last data length marker.
    [self.fileHandle ARK_seekToDataBlockAtIndex:2];
    [self.fileHandle truncateFileAtOffset:(offset2 + 2)];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:1 atFileOffset:offset1];
    [self _assert_seekToDataBlockAtIndex:2 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:3 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:4 seeksToIndex:2 atFileOffset:offset2];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:2 atFileOffset:offset2];
    
    // Truncate everything but three bytes.
    [self.fileHandle truncateFileAtOffset:3];
    
    [self _assert_seekToDataBlockAtIndex:0 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:1 seeksToIndex:0 atFileOffset:offset0];
    [self _assert_seekToDataBlockAtIndex:NSUIntegerMax seeksToIndex:0 atFileOffset:offset0];
}

- (void)_assert_readDataBlock_returnsData:(NSData *)expectedData;
{
    BOOL success = NO;
    NSData *data = [self.fileHandle ARK_readDataBlock:&success];
    
    if (expectedData != nil) {
        XCTAssertEqualObjects(expectedData, data, @"ARK_readDataBlock didn't read expected data.");
    } else {
        XCTAssertNil(data, @"ARK_readDataBlock read unexpected data.");
    }
    
    XCTAssertTrue(success, @"ARK_readDataBlock didn't pass back success when expected.");
}

- (void)test_readDataBlock;
{
    // Read nil when empty.
    [self _assert_readDataBlock_returnsData:nil];
    
    [self.fileHandle ARK_appendDataBlock:self.data_9];
    
    [self.fileHandle seekToFileOffset:0];
    [self _assert_readDataBlock_returnsData:self.data_9];
    [self _assert_readDataBlock_returnsData:nil];
    
    [self.fileHandle ARK_appendDataBlock:self.data_4];
    
    [self.fileHandle seekToFileOffset:0];
    [self _assert_readDataBlock_returnsData:self.data_9];
    [self _assert_readDataBlock_returnsData:self.data_4];
    [self _assert_readDataBlock_returnsData:nil];
}

- (void)test_readDataBlock_detectsCorruptedDataOrInvalidOffset;
{
    [self.fileHandle ARK_appendDataBlock:self.data_7];
    [self.fileHandle ARK_appendDataBlock:self.data_9];
    [self.fileHandle ARK_appendDataBlock:self.data_4];
    
    [self.fileHandle ARK_seekToDataBlockAtIndex:2];
    
    // Check all the offsets within the last data block.
    unsigned long long startOffset = self.fileHandle.offsetInFile;
    for (NSUInteger blockOffset = 1; blockOffset < self.block_4.length; blockOffset++) {
        [self.fileHandle seekToFileOffset:(startOffset + blockOffset)];
        
        BOOL success = YES;
        NSData *data = [self.fileHandle ARK_readDataBlock:&success];
        
        XCTAssertNil(data, @"ARK_readDataBlock should return nil at invalid offset %@.", @(startOffset + blockOffset));
        XCTAssertFalse(success, @"ARK_readDataBlock should pass back !success at invalid offset %@.", @(startOffset + blockOffset));
    }
}

- (void)_test_truncateFileWithData:(NSData *)data toOffset:(unsigned long long)offset;
{
    NSData *expectedData = (offset > data.length) ? [NSData data] : [data subdataWithRange:NSMakeRange((NSUInteger)offset, data.length - (NSUInteger)offset)];
    
    // Test a variety of chunk sizes.
    NSArray *chunkSizes = @[ @(0), @(1), @(2), @(3), @(4), @(8), @(9), @(1023), @(1024), @(NSUIntegerMax) ];
    
    // Test several starting offsets, noting that the parameter is allowed to be past EOF but the file offsets cannot.
    NSUInteger constrainedOffset = MIN(data.length, (NSUInteger)offset);
    NSArray *startOffsets = @[ @(0), @(constrainedOffset / 2), @(constrainedOffset), @(constrainedOffset + (data.length - constrainedOffset) / 2), @(data.length) ];
    NSMutableArray *expectedOffsets = [NSMutableArray new];
    for (NSNumber *startOffset in startOffsets) {
        if (constrainedOffset >= startOffset.integerValue) {
            [expectedOffsets addObject:@(0)];
        } else {
            [expectedOffsets addObject:@(startOffset.integerValue - constrainedOffset)];
        }
    }
    
    for (NSNumber *chunkSize in chunkSizes) {
        for (NSUInteger offsetIndex = 0; offsetIndex < startOffsets.count; offsetIndex++) {
            unsigned long long startOffset = [(NSNumber *)startOffsets[offsetIndex] unsignedLongLongValue];
            unsigned long long expectedOffset = [(NSNumber *)expectedOffsets[offsetIndex] unsignedLongLongValue];
            
            // Restore the contents.
            [self.fileHandle truncateFileAtOffset:0];
            [self.fileHandle writeData:data];
            
            // Seek, truncate and check results.
            [self.fileHandle seekToFileOffset:startOffset];
            [self.fileHandle ARK_truncateFileToOffset:offset maximumChunkSize:chunkSize.unsignedIntegerValue];
            
            unsigned long long resultOffset = self.fileHandle.offsetInFile;
            [self.fileHandle synchronizeFile];
            NSData *resultData = [NSData dataWithContentsOfURL:self.fileURL];
            
            XCTAssert([resultData isEqualToData:expectedData], @"Truncate data of length %@ to offset %@ with chunk size %@ didn't produce expected result.", @(data.length), @(offset), chunkSize);
            XCTAssert(resultOffset == expectedOffset, @"Truncate data of length %@ to offset %@ with start offset %@ didn't result in expected offset %@.", @(data.length), @(offset), @(startOffset), @(expectedOffset));
        }
    }
}

- (void)test_truncateFileToOffset;
{
    // Test empty data.
    [self _test_truncateFileWithData:[NSData data] toOffset:0];
    [self _test_truncateFileWithData:[NSData data] toOffset:1];
    
    // Test single-byte data.
    uint8_t oneByte = 120;
    NSData *singleByteData = [[NSData alloc] initWithBytes:&oneByte length:1];
    [self _test_truncateFileWithData:singleByteData toOffset:0];
    [self _test_truncateFileWithData:singleByteData toOffset:1];
    [self _test_truncateFileWithData:singleByteData toOffset:2];
    
    // Test longer data.
    NSMutableData *sampleData = [NSMutableData new];
    [sampleData appendData:self.block_6];
    [sampleData appendData:self.block_7];
    
    [self _test_truncateFileWithData:sampleData toOffset:0];
    [self _test_truncateFileWithData:sampleData toOffset:1];
    [self _test_truncateFileWithData:sampleData toOffset:10];
    [self _test_truncateFileWithData:sampleData toOffset:(sampleData.length - 1)];
    [self _test_truncateFileWithData:sampleData toOffset:sampleData.length];
    [self _test_truncateFileWithData:sampleData toOffset:(sampleData.length + 1)];
}

- (void)test_throwingExceptionDuringWrite_doesNotCrash;
{
    ARKFileHandle *handle = [[ARKFileHandle alloc] init];
    handle.writeDataBlock = ^{
        @throw [NSException exceptionWithName:NSFileHandleOperationException reason:@"out of space" userInfo:nil];
    };
    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [handle ARK_writeDataBlock:data];
}

- (void)test_throwingExceptionDuringWrite_preventsSubsequentWrites;
{
    [ARKFileHandle ARK_setPreventWritesAfterException:YES];

    XCTestExpectation *expectation = [self expectationWithDescription:@"data was written"];
    ARKFileHandle *handle = [[ARKFileHandle alloc] init];

    __block BOOL hasWrittenDataAtLeastOnce = NO;
    handle.writeDataBlock = ^{
        [expectation fulfill];

        if (hasWrittenDataAtLeastOnce) {
            @throw [NSException exceptionWithName:NSFileHandleOperationException reason:@"out of space" userInfo:nil];
        } else {
            hasWrittenDataAtLeastOnce = YES;
        }
    };

    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [handle ARK_writeDataBlock:data];
    [handle ARK_writeDataBlock:data];
    [handle ARK_writeDataBlock:data];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertTrue(hasWrittenDataAtLeastOnce);
}

- (void)test_throwingExceptionDuringWrite_doesNotPreventSubsequentWrites_whenNotEnabled;
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"data was written"];
    expectation.expectedFulfillmentCount = 3;

    ARKFileHandle *handle = [[ARKFileHandle alloc] init];
    handle.writeDataBlock = ^{
        [expectation fulfill];

        @throw [NSException exceptionWithName:NSFileHandleOperationException reason:@"out of space" userInfo:nil];
    };

    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [handle ARK_writeDataBlock:data];
    [handle ARK_writeDataBlock:data];
    [handle ARK_writeDataBlock:data];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Private Methods

- (NSData *)_blockForData:(NSData *)data;
{
    NSAssert1(data.length > 0 && data.length <= UINT8_MAX, @"Not set up to create data block of size %@", @(data.length));
    
    uint8_t lengthBytes[] = { 0, 0, 0, data.length };
    NSMutableData *block = [NSMutableData dataWithBytes:lengthBytes length:4];
    
    [block appendData:data];
    
    return block;
}

@end
