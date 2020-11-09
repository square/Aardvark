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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Utility for building a tar archive of a Reveal bundle.
///
/// This is not a fully functional tar implementation and is not appropriate for use in general purpose applications.
@interface ARKRevealArchiveBuilder : NSObject

- (BOOL)addDirectoryAtPath:(NSString *)path error:(NSError **)error;

- (BOOL)addFileAtPath:(NSString *)path withData:(NSData *)data error:(NSError **)error;

- (BOOL)addSymbolicLinkAtPath:(NSString *)path toPath:(NSString *)linkPath error:(NSError **)error;

- (NSData *_Nullable)completeArchive;

@end

NS_ASSUME_NONNULL_END
