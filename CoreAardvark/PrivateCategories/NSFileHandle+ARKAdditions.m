//
//  NSFileHandle+ARKAdditions.m
//  CoreAardvark
//
//  Created by Peter Westen on 3/17/15.
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

#import "NSFileHandle+ARKAdditions.h"

#import "AardvarkDefines.h"


NSUInteger const ARKInvalidDataBlockLength = NSUIntegerMax;

/// Type convenience.
typedef unsigned long long ARKFileOffset;

/// These defines must all be kept in sync. Changing them will render files with differently-sized data block lengths unreadable.
#define ARKBlockLengthBytes (sizeof(uint32_t))
#define ARKWriteBigEndianBlockLength OSWriteBigInt32
#define ARKReadBigEndianBlockLength OSReadBigInt32


@implementation NSFileHandle (ARKAdditions)

- (void)ARK_writeDataBlock:(NSData *)dataBlock;
{
    NSUInteger dataBlockLength = dataBlock.length;
    
    ARKCheckCondition(dataBlockLength > 0, , @"Can't write data block %@", dataBlock);
    
    // Be sure to store the length value as big-endian in the file.
    uint8_t dataLengthBytes[ARKBlockLengthBytes] = { };
    ARKWriteBigEndianBlockLength(dataLengthBytes, 0, dataBlockLength);
    NSData *dataLengthData = [NSData dataWithBytes:dataLengthBytes length:ARKBlockLengthBytes];
    
    [self writeData:dataLengthData];
    [self writeData:dataBlock];
}

- (void)ARK_appendDataBlock:(NSData *)dataBlock;
{
    (void)[self seekToEndOfFile];
    [self ARK_writeDataBlock:dataBlock];
}

/// Seeks forward from the beginning of the file, and returns blockIndex on success, or the index of the last block it reached without detecting corruption.
- (NSUInteger)ARK_seekToDataBlockAtIndex:(NSUInteger)blockIndex;
{
    // Simple case.
    if (blockIndex == 0) {
        [self seekToFileOffset:0];
        return 0;
    }
    
    ARKFileOffset endOffset = [self seekToEndOfFile];
    ARKFileOffset currentBlockOffset = 0;
    [self seekToFileOffset:0];
    
    NSUInteger currentBlockIndex = 0;
    while (currentBlockIndex < blockIndex) {
        // Read the block length and break if we're done.
        NSUInteger dataBlockLength = [self _ARK_readDataBlockLength];
        if (dataBlockLength == 0) {
            break;
        }
        
        // If we've detected corruption, seek back and bail out.
        if (dataBlockLength == ARKInvalidDataBlockLength || dataBlockLength > endOffset - self.offsetInFile) {
            [self seekToFileOffset:currentBlockOffset];
            break;
        }
        
        // Seek forward.
        currentBlockIndex++;
        currentBlockOffset = self.offsetInFile + dataBlockLength;
        [self seekToFileOffset:currentBlockOffset];
    }
    
    return currentBlockIndex;
}

- (NSData *)ARK_readDataBlock:(out BOOL *)success;
{
    // Check the length of the file before doing anything.
    ARKFileOffset currentOffset = self.offsetInFile;
    ARKFileOffset endOffset = [self seekToEndOfFile];
    [self seekToFileOffset:currentOffset];
    
    // Read the block length.
    NSUInteger dataBlockLength = [self _ARK_readDataBlockLength];
    
    // Bail out if the length itself was invalid, or there isn't enough remaining data in the file.
    if (dataBlockLength == ARKInvalidDataBlockLength || dataBlockLength > endOffset - self.offsetInFile) {
        [self seekToFileOffset:currentOffset];
        if (success != NULL) {
            *success = NO;
        }
        
        return nil;
    }
    
    if (success != NULL) {
        *success = YES;
    }
    
    return (dataBlockLength > 0) ? [self readDataOfLength:dataBlockLength] : nil;
}

- (void)ARK_truncateFileToOffset:(unsigned long long)offset maximumChunkSize:(NSUInteger)maximumChunkSize;
{
    // If there's nothing to do, bail out.
    if (offset == 0) {
        return;
    }
    
    ARKFileOffset originalOffset = self.offsetInFile;
    ARKFileOffset endOffset = [self seekToEndOfFile];
    
    if (offset >= endOffset) {
        // We've been asked to empty the file.
        [self truncateFileAtOffset:0];
        return;
    }
    
    if (maximumChunkSize == 0) {
        maximumChunkSize = NSUIntegerMax;
    }
    
    ARKFileOffset currentChunkOffset = offset;
    
    while (currentChunkOffset < endOffset) {
        // The purpose of copying data in chunks is to avoid a large high-water mark of memory use, so make sure the NSData objects returned by -[NSFileHandler readDataOfLength:] get cleaned up as we go.
        @autoreleasepool {
            [self seekToFileOffset:currentChunkOffset];
            
            // Enforce the maximum block size, and avoid loss of accuracy when casting from ARKFileOffset to NSUInteger.
            ARKFileOffset remainingDataLength = endOffset - currentChunkOffset;
            NSUInteger chunkLength = (remainingDataLength < maximumChunkSize) ? (NSUInteger)remainingDataLength : maximumChunkSize;
            
            NSData *dataChunk = [self readDataOfLength:chunkLength];
            
            [self seekToFileOffset:(currentChunkOffset - offset)];
            [self writeData:dataChunk];
            
            currentChunkOffset += chunkLength;
        }
    }
    
    // Truncate the file.
    [self truncateFileAtOffset:self.offsetInFile];
    
    // Restore the offset to the same equivalent location.
    [self seekToFileOffset:((originalOffset > offset) ? (originalOffset - offset) : 0)];
}

#pragma mark - Private Methods

- (NSUInteger)_ARK_readDataBlockLength;
{
    NSData *dataBlockLengthData = [self readDataOfLength:ARKBlockLengthBytes];
    
    if (dataBlockLengthData.length == 0) {
        // We're at the end of the file.
        return 0;
    }
    
    if (dataBlockLengthData.length != ARKBlockLengthBytes) {
        // Something went wrong, we read a portion of a block length.
        return ARKInvalidDataBlockLength;
    }
    
    // The value is stored big-endian in the file.
    uint8_t dataBlockLengthBytes[ARKBlockLengthBytes] = { };
    [dataBlockLengthData getBytes:&dataBlockLengthBytes length:ARKBlockLengthBytes];
    return ARKReadBigEndianBlockLength(dataBlockLengthBytes, 0);
}

@end
