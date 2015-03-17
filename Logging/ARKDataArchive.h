//
//  ARKDataArchive.h
//  Aardvark
//
//  Created by Peter Westen on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

@interface ARKDataArchive : NSObject

- (instancetype)initWithArchiveFilename:(NSString *)filename maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSUInteger maximumObjectCount;
@property (nonatomic, readonly) NSUInteger trimmedObjectCount;
@property (nonatomic, copy, readonly) NSURL *archiveFileURL;

- (void)appendArchiveOfObject:(id <NSSecureCoding>)object;
- (void)readObjectsFromArchiveWithCompletionHandler:(void (^)(NSArray *unarchivedObjects))completionHandler;

- (void)trimArchive;
- (void)clearArchive;

- (void)saveArchiveAndWait:(BOOL)wait;

@end
