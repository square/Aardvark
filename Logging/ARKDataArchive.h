//
//  ARKDataArchive.h
//  Aardvark
//
//  Created by Peter Westen on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

@interface ARKDataArchive : NSObject

/// Creates a file at the supplied URL if necessary, or reads in (and validates) the file if it already exists from a previous run.
- (instancetype)initWithURL:(NSURL *)fileURL maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount NS_DESIGNATED_INITIALIZER;

/// The maximum number of archived objects to store in the file.
@property (nonatomic, readonly) NSUInteger maximumObjectCount;

/// The number of objects to keep when trimming down from the maximumObjectCount.
@property (nonatomic, readonly) NSUInteger trimmedObjectCount;

/// The URL of the archive file.
@property (nonatomic, copy, readonly) NSURL *archiveFileURL;

/// Archives the provided object (on the calling thread), and queues appending it to the archive.
- (void)appendArchiveOfObject:(id <NSSecureCoding>)object;

/// Reads in all contents of the archive, unarchives each object, and returns them on the main thread.
- (void)readObjectsFromArchiveWithCompletionHandler:(void (^)(NSArray *unarchivedObjects))completionHandler;

/// Empties the archive (but does not remove the file).
- (void)clearArchive;

/// Ensures the archive is persisted on the file system, synchronously if requested.
- (void)saveArchiveAndWait:(BOOL)wait;

@end
