//
//  NSFileHandle+ARKAdditions.m
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "NSFileHandle+ARKAdditions.h"


NSUInteger const ARKInvalidDataBlockLength = NSUIntegerMax;


@implementation NSFileHandle (ARKAdditions)

- (void)ARK_writeDataBlock:(NSData *)dataBlock;
{
    NSUInteger dataBlockLength = dataBlock.length;
    
    ARKCheckCondition(dataBlockLength > 0, , @"Can't write data block %@", dataBlock);
    
    // Be sure to store the length value as big-endian in the file.
    uint32_t dataLengthBytes = OSSwapHostToBigInt32(dataBlockLength);
    [self writeData:[NSData dataWithBytes:&dataLengthBytes length:sizeof(dataLengthBytes)]];
    
    [self writeData:dataBlock];
}

- (NSUInteger)ARK_readDataBlockLength;
{
    uint32_t dataLengthBytes = 0;
    
    NSData *dataLengthData = [self readDataOfLength:sizeof(dataLengthBytes)];
    if (dataLengthData.length == 0) {
        // We're at the end of the file.
        return 0;
    }
    
    if (dataLengthData.length != sizeof(dataLengthBytes)) {
        // Something went wrong, we read a portion of a block length.
        return ARKInvalidDataBlockLength;
    }
    
    // The value is stored big-endian in the file.
    [dataLengthData getBytes:&dataLengthBytes];
    return OSSwapBigToHostInt32(dataLengthBytes);
}

- (BOOL)ARK_seekForwardByDataBlockLength:(NSUInteger)dataBlockLength;
{
    if (dataBlockLength == ARKInvalidDataBlockLength) {
        return NO;
    }
    
    unsigned long long newOffset = self.offsetInFile + dataBlockLength;
    unsigned long long endOffset = [self seekToEndOfFile];
    
    if (endOffset < newOffset) {
        return NO;
    }
    
    [self seekToFileOffset:newOffset];
    return YES;
}

- (void)ARK_truncateFileToOffset:(unsigned long long)offset maximumChunkSize:(NSUInteger)maximumChunkSize;
{
    // If there's nothing to do, bail out.
    if (offset == 0) {
        return;
    }
    
    unsigned long long originalOffset = self.offsetInFile;
    unsigned long long endOffset = [self seekToEndOfFile];
    
    if (offset >= endOffset) {
        // We've been asked to empty the file.
        [self truncateFileAtOffset:0];
        return;
    }
    
    if (maximumChunkSize == 0) {
        maximumChunkSize = NSUIntegerMax;
    }
    
    unsigned long long currentChunkOffset = offset;
    
    while (currentChunkOffset < endOffset) {
        // The purpose of copying data in chunks is to avoid a large high-water mark of memory use, so make sure the NSData objects returned by -[NSFileHandler readDataOfLength:] get cleaned up as we go.
        @autoreleasepool {
            [self seekToFileOffset:currentChunkOffset];
            
            // Enforce the maximum block size, and avoid loss of accuracy when casting from ull to NSUInteger.
            unsigned long long remainingDataLength = endOffset - currentChunkOffset;
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

@end
