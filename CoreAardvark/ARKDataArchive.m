//
//  ARKDataArchive.m
//  CoreAardvark
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

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"

#import "AardvarkDefines.h"
#import "NSFileHandle+ARKAdditions.h"


NSUInteger const ARKMaximumChunkSizeForTrimOperation = (1024 * 1024);


@interface ARKDataArchive ()

@property (nonatomic, readonly) NSFileHandle *fileHandle;
@property (nonatomic, readonly) NSOperationQueue *fileOperationQueue;

@property (nonatomic) NSUInteger objectCount;

@end


@implementation ARKDataArchive

#pragma mark - Initialization

- (nullable instancetype)initWithURL:(nonnull NSURL *)fileURL maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount;
{
    ARKCheckCondition([fileURL isFileURL], nil, @"Must provide a file URL!");
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        [[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:nil attributes:nil];
    }
    
    NSError *error = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingURL:fileURL error:&error];
    
    ARKCheckCondition(fileHandle != nil, nil, @"Couldn't create file handle for %@, got error %@", fileURL, error);
    
    _archiveFileURL = [fileURL copy];
    _fileHandle = fileHandle;
    
    _maximumObjectCount = maximumObjectCount;
    _trimmedObjectCount = trimmedObjectCount;
    
    _fileOperationQueue = [NSOperationQueue new];
    _fileOperationQueue.name = [NSString stringWithFormat:@"%@ File Operation Queue", self];
    _fileOperationQueue.maxConcurrentOperationCount = 1;
    
#ifdef __IPHONE_8_0
    if ([_fileOperationQueue respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        _fileOperationQueue.qualityOfService = NSQualityOfServiceBackground;
    }
#endif
    
    [_fileOperationQueue addOperationWithBlock:^{
        // Count the number of (valid) archived objects.
        self.objectCount = [self.fileHandle ARK_seekToDataBlockAtIndex:NSUIntegerMax];
        
        // Truncate corrupted content (if any).
        [self.fileHandle truncateFileAtOffset:self.fileHandle.offsetInFile];
        
        // If maximumObjectCount is smaller than what was used previously, we may need to trim.
        [self _trimArchiveIfNecessary_inFileOperationQueue];
    }];
    
    return self;
}

#pragma mark - Public Methods

- (void)appendArchiveOfObject:(nonnull id <NSSecureCoding>)object;
{
    NSData *data = nil;
    
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
    }
    @catch (NSException *exception) {
        ARKCheckCondition(NO, , @"Couldn't archive object %@", object);
    }
    
    if (data.length > 0) {
        [self.fileOperationQueue addOperationWithBlock:^{
            [self.fileHandle ARK_appendDataBlock:data];
            self.objectCount++;
            
            [self _trimArchiveIfNecessary_inFileOperationQueue];
        }];
    }
}

- (void)readObjectsFromArchiveWithCompletionHandler:(nonnull void (^)(NSArray * _Nonnull unarchivedObjects))completionHandler;
{
    ARKCheckCondition(completionHandler != NULL, , @"Must provide a completionHandler!");
    
    NSBlockOperation *readOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSMutableArray *unarchivedObjects = [NSMutableArray arrayWithCapacity:self.objectCount];
        
        if (self.objectCount > 0) {
            [self.fileHandle ARK_seekToDataBlockAtIndex:0];
            
            while (YES) {
                BOOL success = NO;
                NSData *objectData = [self.fileHandle ARK_readDataBlock:&success];
                
                if (!success) {
                    NSLog(@"ERROR: -[%@ %@] corrupted archive at index %@ of %@ in %@.",
                          NSStringFromClass([self class]), NSStringFromSelector(_cmd),
                          @(unarchivedObjects.count), @(self.objectCount),
                          self.archiveFileURL);
                    
                    // We can't trust anything in the file from here forward.
                    [self.fileHandle truncateFileAtOffset:self.fileHandle.offsetInFile];
                    break;
                }
                
                if (objectData == nil) {
                    // We're done.
                    break;
                }
                
                id object = nil;
                @try {
                    object = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                }
                @catch (NSException *exception) {
                    // The structure of the archive itself isn't corrupted, just the data itself, so ignore and continue.
                    continue;
                }
                
                if (object != nil) {
                    [unarchivedObjects addObject:object];
                }
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(unarchivedObjects);
        }];
    }];
    
    // Set the QoS of this operation to be high, since objects are typically requested in order to fulfill a user operation.
#ifdef __IPHONE_8_0
    if ([readOperation respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
        readOperation.qualityOfService = NSQualityOfServiceUserInitiated;
    }
#endif
    
    [self.fileOperationQueue addOperation:readOperation];
}

- (void)clearArchiveWithCompletionHandler:(nullable dispatch_block_t)completionHandler;
{
    [self.fileOperationQueue addOperationWithBlock:^{
        self.objectCount = 0;
        [self.fileHandle truncateFileAtOffset:0];
        [self _saveArchive_inFileOperationQueue];
        
        if (completionHandler != NULL) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:completionHandler];
        }
    }];
}

- (void)saveArchiveAndWait:(BOOL)wait;
{
    NSBlockOperation *saveOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self _saveArchive_inFileOperationQueue];
    }];
    
    if (wait) {
        // Set the QoS of this operation to be high if the calling code is waiting for it.
#ifdef __IPHONE_8_0
        if ([saveOperation respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
            saveOperation.qualityOfService = NSQualityOfServiceUserInitiated;
        }
#endif
    }
    
    if (wait) {
        [self.fileOperationQueue addOperations:@[ saveOperation ] waitUntilFinished:YES];
    } else {
        [self.fileOperationQueue addOperation:saveOperation];
    }
}

#pragma mark - Testing Methods

- (void)waitUntilAllOperationsAreFinished;
{
    [self.fileOperationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

- (void)_trimArchiveIfNecessary_inFileOperationQueue;
{
    if (self.maximumObjectCount == 0 || self.maximumObjectCount == NSUIntegerMax) {
        return;
    }
    
    NSUInteger objectCount = self.objectCount;
    
    if (objectCount > self.maximumObjectCount && objectCount > self.trimmedObjectCount) {
        NSUInteger blockIndex = objectCount - self.trimmedObjectCount;
        NSUInteger seekIndex = [self.fileHandle ARK_seekToDataBlockAtIndex:blockIndex];
        
        if (seekIndex == blockIndex) {
            [self.fileHandle ARK_truncateFileToOffset:self.fileHandle.offsetInFile maximumChunkSize:ARKMaximumChunkSizeForTrimOperation];
            self.objectCount = self.trimmedObjectCount;
            
        } else {
            NSLog(@"ERROR: -[%@ %@] corrupted archive at index %@ of %@ in %@.",
                  NSStringFromClass([self class]), NSStringFromSelector(_cmd),
                  @(seekIndex), @(objectCount),
                  self.archiveFileURL);
            
            // Trim from here forward.
            [self.fileHandle truncateFileAtOffset:self.fileHandle.offsetInFile];
            self.objectCount = seekIndex;
        }
    }
}

- (void)_saveArchive_inFileOperationQueue;
{
    [self.fileHandle synchronizeFile];
}

@end
