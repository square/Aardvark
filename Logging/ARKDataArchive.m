//
//  ARKDataArchive.m
//  Aardvark
//
//  Created by Peter Westen on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "ARKDataArchive.h"
#import "ARKDataArchive_Testing.h"

#import "NSFileHandle+ARKAdditions.h"


#define BREAK_IF_ARCHIVE_IS_CORRUPTED(condition) \
    { \
        if ((condition)) { \
            NSLog(@"ERROR: -[%@ %@] corrupted archive at %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.archiveFileURL); \
            [self _clearArchive]; \
            break; \
        } \
    }


NSUInteger const ARKMaximumChunkSizeForTrimOperation = (1024 * 1024);


@interface ARKDataArchive ()

@property (nonatomic, strong, readonly) NSOperationQueue *fileOperationQueue;
@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;

@property (nonatomic) NSUInteger objectCount;

@end


@implementation ARKDataArchive

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)fileURL maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount;
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
        // Count the number of objects and validate the structure of the file.
        [self.fileHandle seekToFileOffset:0];
        
        while (YES) {
            NSUInteger dataLength = [self.fileHandle ARK_readDataBlockLength];
            if (dataLength == 0) {
                // We're done.
                break;
            }
            
            BREAK_IF_ARCHIVE_IS_CORRUPTED(dataLength == ARKInvalidDataBlockLength);
            
            BREAK_IF_ARCHIVE_IS_CORRUPTED(![self.fileHandle ARK_seekForwardByDataBlockLength:dataLength]);
            
            self.objectCount++;
        }
        
        // Trim if appropriate.
        [self _trimArchiveIfNecessary];
    }];
    
    return self;
}

#pragma mark - Public Methods

- (void)appendArchiveOfObject:(id <NSSecureCoding>)object;
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
            [self.fileHandle seekToEndOfFile];
            [self.fileHandle ARK_writeDataBlock:data];
            
            self.objectCount++;
            
            [self _trimArchiveIfNecessary];
        }];
    }
}

- (void)readObjectsFromArchiveWithCompletionHandler:(void (^)(NSArray *unarchivedObjects))completionHandler;
{
    ARKCheckCondition(completionHandler != NULL, , @"Must provide a completionHandler!");
    
    NSBlockOperation *readOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSMutableArray *unarchivedObjects = [NSMutableArray arrayWithCapacity:self.objectCount];
        if (self.objectCount > 0) {
            [self.fileHandle seekToFileOffset:0];
            
            while (YES) {
                NSUInteger dataLength = [self.fileHandle ARK_readDataBlockLength];
                if (dataLength == 0) {
                    break;
                }
                
                BREAK_IF_ARCHIVE_IS_CORRUPTED(dataLength == NSUIntegerMax);
                
                NSData *objectData = [self.fileHandle readDataOfLength:dataLength];
                BREAK_IF_ARCHIVE_IS_CORRUPTED(objectData == nil || objectData.length != dataLength);
                
                id object = nil;
                
                @try {
                    object = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                }
                @catch (NSException *exception) {
                    // We don't clear the archive if an individual object can't be unarchived, only if the structure of the archive itself is corrupted.
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

- (void)clearArchive;
{
    [self.fileOperationQueue addOperationWithBlock:^{
        [self _clearArchive];
    }];
}

- (void)saveArchiveAndWait:(BOOL)wait;
{
    NSBlockOperation *saveOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self.fileHandle synchronizeFile];
    }];
    
    if (wait) {
        // Set the QoS of this operation to be high if the calling code is waiting for it.
#ifdef __IPHONE_8_0
        if ([saveOperation respondsToSelector:@selector(setQualityOfService:)] /* iOS 8 or later */) {
            saveOperation.qualityOfService = NSQualityOfServiceUserInitiated;
        }
#endif
    }
    
    [self.fileOperationQueue addOperation:saveOperation];
    
    if (wait) {
        [self.fileOperationQueue waitUntilAllOperationsAreFinished];
    }
}

#pragma mark - Testing Methods

- (int)archiveFileDescriptor;
{
    return self.fileHandle.fileDescriptor;
}

#pragma mark - Private Methods

- (void)_trimArchiveIfNecessary;
{
    if (self.maximumObjectCount == 0 || self.maximumObjectCount == NSUIntegerMax) {
        return;
    }
    
    NSUInteger objectCount = self.objectCount;
    
    if (objectCount > self.maximumObjectCount && objectCount > self.trimmedObjectCount) {
        NSUInteger numberOfLogsToTrim = (objectCount - self.trimmedObjectCount);
        
        [self.fileHandle seekToFileOffset:0];
        while (YES) {
            if (numberOfLogsToTrim == 0) {
                [self.fileHandle ARK_truncateFileToOffset:self.fileHandle.offsetInFile maximumChunkSize:ARKMaximumChunkSizeForTrimOperation];
                self.objectCount = self.trimmedObjectCount;
                break;
            }
            
            BREAK_IF_ARCHIVE_IS_CORRUPTED(![self.fileHandle ARK_seekForwardByDataBlockLength:[self.fileHandle ARK_readDataBlockLength]]);
            
            numberOfLogsToTrim--;
        }
    }
}

- (void)_clearArchive;
{
    self.objectCount = 0;
    [self.fileHandle truncateFileAtOffset:0];
}

@end
