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

@import Foundation;

#import <AardvarkReveal/ARKRevealArchiveBuilder.h>


struct header_posix_ustar {
    char name[100];
    char mode[8];
    char uid[8];
    char gid[8];
    char size[12];
    char mtime[12];
    char checksum[8];
    char typeflag[1];
    char linkname[100];
    char magic[6];
    char version[2];
    char uname[32];
    char gname[32];
    char devmajor[8];
    char devminor[8];
    char prefix[155];
    char pad[12];
};

#define TAR_BLOCK_LENGTH 512


@interface ARKRevealArchiveBuilder (Testing)

- (instancetype)initWithModificationDate:(NSTimeInterval)modificationDate;

@property (nonatomic, readonly) NSMutableData *archiveData;

+ (struct header_posix_ustar)_headerForPath:(NSString *)path
                                       type:(char)type
                                   fileSize:(int64_t)fileSize
                                   linkName:(NSString *)linkName
                           modificationDate:(NSTimeInterval)modificationDate
                                      error:(NSError **)error;

@end
