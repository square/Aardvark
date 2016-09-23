//
//  NSFileHandle+ARKAdditions.h
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

@import Foundation;


extern NSUInteger const ARKInvalidDataBlockLength;


@interface NSFileHandle (ARKAdditions)

/// Writes the length of dataBlock, and then its contents. Note: this writes (or over-writes) at the current offsetInFile.
- (void)ARK_writeDataBlock:(nonnull NSData *)dataBlock;

/// Seeks to the end of the file before writing.
- (void)ARK_appendDataBlock:(nonnull NSData *)dataBlock;

/// Seeks forward from the beginning of the file, and returns blockIndex on success, or the index of the last block it reached without detecting corruption.
- (NSUInteger)ARK_seekToDataBlockAtIndex:(NSUInteger)blockIndex;

/// Reads the length of the data block, followed by the data itself. Returns nil at the end of the file, and passes back NO if corruption was detected (without changing the current offsetInFile).
- (nullable NSData *)ARK_readDataBlock:(nonnull out BOOL *)success;

/// Truncates the file from the beginning to the specified offset, moving data in chunks no larger than maximumChunkSize (to constrain the memory usage of the operation, at the expense of more processor and I/O time). Pass 0 or NSUIntegerMax to impose no limit.
- (void)ARK_truncateFileToOffset:(unsigned long long)offset maximumChunkSize:(NSUInteger)maximumChunkSize;

@end
