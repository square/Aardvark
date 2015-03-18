//
//  ARKDataArchive.m
//  Aardvark
//
//  Created by Peter Westen on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "ARKDataArchive.h"


#define BREAK_IF_ARCHIVE_IS_CORRUPT(condition) \
    { \
        if ((condition)) { \
            NSLog(@"ERROR: -[%@ %@] corrupted archive at %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.archiveFileURL); \
            [self _clearArchive]; \
            break; \
        } \
    }


@interface NSFileHandle (ARKDataExtensions)

- (NSUInteger)readDataBlockLength;
- (void)writeDataBlockLength:(NSUInteger)dataBlockLength;
- (BOOL)seekForwardByDataBlockLength:(NSUInteger)dataBlockLength;
- (void)truncateFileToOffset:(unsigned long long)offset maximumBlockSize:(NSUInteger)maximumBlockSize;

@end


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
    
    if (fileHandle == nil || error != nil) {
        return nil;
    }
    
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
            NSUInteger dataLength = [self.fileHandle readDataBlockLength];
            if (dataLength == 0) {
                // We're done.
                break;
            }
            
            BREAK_IF_ARCHIVE_IS_CORRUPT(dataLength == NSUIntegerMax);
            
            BREAK_IF_ARCHIVE_IS_CORRUPT(![self.fileHandle seekForwardByDataBlockLength:dataLength]);
            
            self.objectCount++;
        }
        
        // Trim if appropriate.
        [self _trimArchiveIfNecessary];
    }];
    
    return self;
}

- (instancetype)initWithApplicationSupportFilename:(NSString *)filename maximumObjectCount:(NSUInteger)maximumObjectCount trimmedObjectCount:(NSUInteger)trimmedObjectCount;
{
    ARKCheckCondition(filename.length > 0, nil, @"Must provide a filename!");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *archivePath = [[applicationSupportDirectory stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier] stringByAppendingPathComponent:filename];
    
    return [self initWithURL:[NSURL fileURLWithPath:archivePath isDirectory:NO] maximumObjectCount:maximumObjectCount trimmedObjectCount:trimmedObjectCount];
}

- (void)dealloc;
{
    [self.fileHandle closeFile];
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
            [self.fileHandle writeDataBlockLength:data.length];
            [self.fileHandle writeData:data];
            
            self.objectCount++;
            
            [self _trimArchiveIfNecessary];
        }];
    }
}

- (void)readObjectsFromArchiveWithCompletionHandler:(void (^)(NSArray *unarchivedObjects))completionHandler;
{
    if (completionHandler == NULL) {
        return;
    }
    
    NSBlockOperation *readOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSMutableArray *unarchivedObjects = [NSMutableArray arrayWithCapacity:self.objectCount];
        if (self.objectCount > 0) {
            [self.fileHandle seekToFileOffset:0];
            
            while (YES) {
                NSUInteger dataLength = [self.fileHandle readDataBlockLength];
                if (dataLength == 0) {
                    break;
                }
                
                BREAK_IF_ARCHIVE_IS_CORRUPT(dataLength == NSUIntegerMax);
                
                NSData *objectData = [self.fileHandle readDataOfLength:dataLength];
                BREAK_IF_ARCHIVE_IS_CORRUPT(objectData == nil || objectData.length != dataLength);
                
                id object = nil;
                
                @try {
                    object = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                }
                @catch (NSException *exception) {
                    // We don't clear the archive if an individual object can't be unarchived, since the file itself is still well-formed.
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
        // Set the QoS of this operation to be high if the calling code is waiting on it.
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

- (void)waitUntilAllOperationsAreFinished;
{
    [self.fileOperationQueue waitUntilAllOperationsAreFinished];
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
                [self.fileHandle truncateFileToOffset:self.fileHandle.offsetInFile maximumBlockSize:(1024 * 1024)];
                self.objectCount = self.trimmedObjectCount;
                break;
            }
            
            BREAK_IF_ARCHIVE_IS_CORRUPT(![self.fileHandle seekForwardByDataBlockLength:[self.fileHandle readDataBlockLength]]);
            
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


#pragma mark -


@implementation NSFileHandle (ARKDataExtensions)

- (NSUInteger)readDataBlockLength;
{
    uint32_t dataLengthBytes = 0;
    
    NSData *dataLengthData = [self readDataOfLength:sizeof(dataLengthBytes)];
    if (dataLengthData.length == 0) {
        // We're at the end of the file.
        return 0;
    }
    
    if (dataLengthData.length != sizeof(dataLengthBytes)) {
        // Something went wrong, we read a portion of a block length.
        return NSUIntegerMax;
    }
    
    // The value is stored big-endian in the file.
    [dataLengthData getBytes:&dataLengthBytes];
    return OSSwapBigToHostInt32(dataLengthBytes);
}

- (void)writeDataBlockLength:(NSUInteger)dataBlockLength;
{
    // Store the value as big-endian in the file.
    uint32_t dataLengthBytes = OSSwapHostToBigInt32(dataBlockLength);
    [self writeData:[NSData dataWithBytes:&dataLengthBytes length:sizeof(dataLengthBytes)]];
}

- (BOOL)seekForwardByDataBlockLength:(NSUInteger)dataBlockLength;
{
    if (dataBlockLength == NSUIntegerMax) {
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

- (void)truncateFileToOffset:(unsigned long long)offset maximumBlockSize:(NSUInteger)maximumBlockSize;
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
    
    if (maximumBlockSize == 0) {
        maximumBlockSize = NSUIntegerMax;
    }
    
    unsigned long long currentBlockOffset = offset;
    
    while (currentBlockOffset < endOffset) {
        @autoreleasepool {
            [self seekToFileOffset:currentBlockOffset];
            
            // Enforce the maximum block size, and avoid loss of accuracy when casting from ull to NSUInteger.
            unsigned long long remainingDataLength = endOffset - currentBlockOffset;
            NSUInteger blockLength = (remainingDataLength < maximumBlockSize) ? (NSUInteger)remainingDataLength : maximumBlockSize;
            
            NSData *dataBlock = [self readDataOfLength:blockLength];
            
            [self seekToFileOffset:(currentBlockOffset - offset)];
            [self writeData:dataBlock];
            
            currentBlockOffset += blockLength;
        }
    }
    
    // Truncate the file.
    [self truncateFileAtOffset:self.offsetInFile];
    
    // Restore the offset to the same equivalent location.
    [self seekToFileOffset:((originalOffset > offset) ? (originalOffset - offset) : 0)];
}

@end

