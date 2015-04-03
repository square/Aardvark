//
//  ARKDataArchive.h
//  Aardvark
//
//  Created by Peter Westen on 3/16/15.
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

/// Incrementally persists data to disk. All methods and properties on this class are threadsafe.
@interface ARKDataArchive : NSObject

/// Creates a file at the supplied URL if necessary, or reads in (and validates) the file if it already exists from a previous run.
- (instancetype)initWithURL:(NSURL *)fileURL maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount __attribute__((nonnull(1))) NS_DESIGNATED_INITIALIZER;

/// The maximum number of archived objects to store in the file.
@property (nonatomic, readonly) NSUInteger maximumObjectCount;

/// The number of objects to keep when trimming down from the maximumObjectCount.
@property (nonatomic, readonly) NSUInteger trimmedObjectCount;

/// The URL of the archive file.
@property (nonatomic, copy, readonly) NSURL *archiveFileURL;

/// Archives the provided object (on the calling thread), and queues appending it to the archive.
- (void)appendArchiveOfObject:(id <NSSecureCoding>)object;

/// Reads in all contents of the archive, unarchives each object, and returns them on the main thread.
- (void)readObjectsFromArchiveWithCompletionHandler:(void (^)(NSArray *unarchivedObjects))completionHandler __attribute__((nonnull(1)));

/// Empties the archive (but does not remove the file). Completion handler is called on the main queue.
- (void)clearArchiveWithCompletionHandler:(dispatch_block_t)completionHandler;

/// Ensures the archive is persisted on the file system, synchronously if requested.
- (void)saveArchiveAndWait:(BOOL)wait;

@end
