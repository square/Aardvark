//
//  NSFileHandle+ARKAdditions.h
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

extern NSUInteger const ARKInvalidDataBlockLength;


@interface NSFileHandle (ARKAdditions)

/// Writes the length of dataBlock, and then its contents. Note: this writes (or over-writes) at the current offsetInFile.
- (void)ARK_writeDataBlock:(NSData *)dataBlock;

/// Seeks to the end of the file before writing.
- (void)ARK_appendDataBlock:(NSData *)dataBlock;

/// Reads the length of the following data block (or 0 at EOF). The current file offset must be at a block length marker. If the current offsetInFile is too close to EOF, returns ARKInvalidDataBlockLength.
- (NSUInteger)ARK_readDataBlockLength;

/// Advances the file offset by the specified number of bytes, as returned from a prior call to -ARK_readDataBlockLength. Returns NO if dataBlockLength is ARKInvalidDataBlockLength or too few bytes remain in the file.
- (BOOL)ARK_seekForwardByDataBlockLength:(NSUInteger)dataBlockLength;

/// Truncates the file from the beginning to the specified offset, moving data in chunks no larger than maximumChunkSize (to constrain the memory usage of the operation, at the expense of more processor and I/O time). Pass 0 or NSUIntegerMax to impose no limit.
- (void)ARK_truncateFileToOffset:(unsigned long long)offset maximumChunkSize:(NSUInteger)maximumChunkSize;

@end
