//
//  NSFileHandle+ARKAdditions.h
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

extern NSUInteger const ARKInvalidDataBlockLength;


@interface NSFileHandle (ARKAdditions)

/// Writes the length of data block before its contents.
- (void)ARK_writeDataBlock:(NSData *)dataBlock;

/// Reads the length of the following data block. The current file offset must be at a block length marker.
- (NSUInteger)ARK_readDataBlockLength;

/// Advances the file offset by the specified number of bytes, as returned from a prior call to -ARK_readDataBlockLength.
- (BOOL)ARK_seekForwardByDataBlockLength:(NSUInteger)dataBlockLength;

/// Truncates the file from the beginning to the specified offset, moving data in chunks no larger than maximumChunkSize.
- (void)ARK_truncateFileToOffset:(unsigned long long)offset maximumChunkSize:(NSUInteger)maximumChunkSize;

@end
