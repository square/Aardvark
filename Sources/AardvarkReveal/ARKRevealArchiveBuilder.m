//
//  Copyright 2020 Square, Inc.
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

#import "ARKRevealArchiveBuilder.h"
#import "ARKRevealArchiveBuilder_Testing.h"

#import <tar.h>





NSString *const ARKRevealArchiveBuilderErrorDomain = @"ARKRevealArchiveBuilderErrorDomain";
NSInteger const ARKRevealArchiveBuilderErrorCodeAlreadyComplete = 1;
NSInteger const ARKRevealArchiveBuilderErrorCodeDataAllocationFailure = 2;
NSInteger const ARKRevealArchiveBuilderErrorCodeHeaderWriteFailure = 3;


@interface ARKRevealArchiveBuilder ()

@property (nonatomic, readwrite) NSMutableData *archiveData;
@property (nonatomic) NSTimeInterval modificationDate;
@property (nonatomic) BOOL isComplete;

@end


@implementation ARKRevealArchiveBuilder

// Some of the functionality in this class is based on tarkit, which is released under the Apache 2.0 license.
// See <https://github.com/daltoniam/tarkit>.

#pragma mark - Life Cycle

- (instancetype)init;
{
    return [self initWithModificationDate:[[NSDate date] timeIntervalSince1970]];
}

- (instancetype)initWithModificationDate:(NSTimeInterval)modificationDate;
{
    if (self = [super init]) {
        _archiveData = [NSMutableData data];
        _modificationDate = modificationDate;
        _isComplete = NO;
    }

    return self;
}

#pragma mark - Public Methods

- (BOOL)addDirectoryAtPath:(NSString *)path error:(NSError **)error;
{
    @synchronized (_archiveData) {
        if (_isComplete) {
            *error = [NSError errorWithDomain:ARKRevealArchiveBuilderErrorDomain
                                         code:ARKRevealArchiveBuilderErrorCodeAlreadyComplete
                                     userInfo:nil];
            return NO;
        }

        NSError *headerError;
        struct header_posix_ustar header = [[self class] _headerForPath:path
                                                                   type:DIRTYPE
                                                               fileSize:0
                                                               linkName:nil
                                                       modificationDate:_modificationDate
                                                                  error:&headerError];

        if (headerError != nil) {
            *error = headerError;
            return NO;
        }

        [_archiveData appendBytes:&header length:sizeof(struct header_posix_ustar)];

        return YES;
    }
}

- (BOOL)addFileAtPath:(NSString *)path withData:(NSData *)data error:(NSError **)error;
{
    @synchronized (_archiveData) {
        if (_isComplete) {
            *error = [NSError errorWithDomain:ARKRevealArchiveBuilderErrorDomain
                                         code:ARKRevealArchiveBuilderErrorCodeAlreadyComplete
                                     userInfo:nil];
            return NO;
        }

        // The archive uses fixed length blocks, so zero out any remaining space in the last block.
        NSData *padding = nil;
        NSUInteger overflowByteCount = (data.length % TAR_BLOCK_LENGTH);
        if (overflowByteCount != 0) {
            padding = [NSMutableData dataWithLength:(TAR_BLOCK_LENGTH - overflowByteCount)];

            if (padding == nil) {
                *error = [NSError errorWithDomain:ARKRevealArchiveBuilderErrorDomain
                                             code:ARKRevealArchiveBuilderErrorCodeDataAllocationFailure
                                         userInfo:nil];
                return NO;
            }
        }

        NSError *headerError;
        struct header_posix_ustar header = [[self class] _headerForPath:path
                                                                   type:REGTYPE
                                                               fileSize:data.length
                                                               linkName:nil
                                                       modificationDate:_modificationDate
                                                                  error:&headerError];

        if (headerError != nil) {
            *error = headerError;
            return NO;
        }

        [_archiveData appendBytes:&header length:sizeof(struct header_posix_ustar)];
        [_archiveData appendData:data];
        [_archiveData appendData:padding];

        return YES;
    }
}

- (BOOL)addSymbolicLinkAtPath:(NSString *)path toPath:(NSString *)linkPath error:(NSError **)error;
{
    @synchronized (_archiveData) {
        if (_isComplete) {
            *error = [NSError errorWithDomain:ARKRevealArchiveBuilderErrorDomain
                                         code:ARKRevealArchiveBuilderErrorCodeAlreadyComplete
                                     userInfo:nil];
            return NO;
        }

        NSError *headerError;
        struct header_posix_ustar header = [[self class] _headerForPath:path
                                                                   type:SYMTYPE
                                                               fileSize:0
                                                               linkName:linkPath
                                                       modificationDate:_modificationDate
                                                                  error:&headerError];

        if (headerError != nil) {
            *error = headerError;
            return NO;
        }

        [_archiveData appendBytes:&header length:sizeof(struct header_posix_ustar)];

        return YES;
    }
}

- (NSData *)completeArchive;
{
    @synchronized (_archiveData) {
        if (_isComplete) {
            return _archiveData;
        }

        NSData *emptyBlock = [NSMutableData dataWithLength:TAR_BLOCK_LENGTH];
        if (emptyBlock == nil) {
            return nil;
        }

        [_archiveData appendData:emptyBlock];
        [_archiveData appendData:emptyBlock];

        _isComplete = YES;

        return _archiveData;
    }
}

#pragma mark - Private Methods

+ (struct header_posix_ustar)_headerForPath:(NSString *)path
                                       type:(char)type
                                   fileSize:(int64_t)fileSize
                                   linkName:(NSString *)linkName
                           modificationDate:(NSTimeInterval)modificationDate
                                      error:(NSError **)error;
{
    // Create the header based on the Unix Standard TAR format.
    // See <https://www.freebsd.org/cgi/man.cgi?query=tar&apropos=0&sektion=5&manpath=FreeBSD+7.0-RELEASE&arch=default&format=html>.
    struct header_posix_ustar header = {
        /* name */      {},
        /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
        /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* size */      {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
        /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
        /* checksum */  {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '},
        /* typeflag */  type,
        /* linkname */  {},
        /* magic */     TMAGIC,
        /* version */   TVERSION,
        /* uname */     {},
        /* gname */     {},
        /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* prefix */    {},
        /* pad */       {}
    };

    // Per the ustar spec, we should check the length of the file name and split it across the `name` and `prefix`
    // fields if it's too long. In practice, we have a very shallow file hierarchy and short file names, so we should
    // never overflow past the `name` field.

    const char *_Nullable pathString = [path cStringUsingEncoding:NSUTF8StringEncoding];
    memcpy(&header.name, pathString, [path lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);

    if (linkName != nil) {
        const char *_Nullable linkString = [linkName cStringUsingEncoding:NSUTF8StringEncoding];
        memcpy(&header.linkname, linkString, [linkName lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    }

    int failed = 0;

    failed |= write_ascii_octal(fileSize, (char *)(&header.size), sizeof(header.size) - 1);

    failed |= write_ascii_octal(modificationDate, (char *)(&header.mtime), sizeof(header.mtime) - 1);

    int64_t checksum = 0;
    for (int i = 0 ; i < TAR_BLOCK_LENGTH ; i++) {
        checksum += 255 & (int64_t)(((char *)&header)[i]);
    }
    failed |= write_ascii_octal(checksum, (char *)&header.checksum, 6);

    if (failed) {
        *error = [NSError errorWithDomain:ARKRevealArchiveBuilderErrorDomain
                                     code:ARKRevealArchiveBuilderErrorCodeHeaderWriteFailure
                                 userInfo:nil];
    }

    return header;
}

/// Writes the value `v` as an ASCII representation of an octal number of length `s` to `p`.
///
/// Returns `0` if successful, otherwise `1`.
static int write_ascii_octal(int64_t v, char *p, int s) {
    // Octal values can't be negative.
    if (v < 0) {
        return 1;
    }

    // Start at the least significant digit and work backwards. Fill the entire length of the string, including leading
    // zeros.
    p += s;
    while (s-- > 0) {
        *--p = (char)('0' + (v & 0b111));
        v >>= 3;
    }

    // Check that the value didn't overflow.
    return (v == 0) ? 0 : 1;
}

@end
