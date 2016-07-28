//
//  NSURL+ARKAdditions.m
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

#import "NSURL+ARKAdditions.h"

#import "AardvarkDefines.h"


@implementation NSURL (ARKAdditions)

+ (instancetype)ARK_fileURLWithApplicationSupportFilename:(NSString *)filename;
{
    ARKCheckCondition(filename.length > 0, nil, @"Must provide a filename!");
    ARKCheckCondition([filename pathComponents].count == 1, nil, @"Must provide a filename, not a path!");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *archivePath = [applicationSupportDirectory stringByAppendingPathComponent:filename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:applicationSupportDirectory]) {
        NSError *error = nil;
        ARKCheckCondition([fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:&error], nil, @"Could not create directory %@ due to error %@", applicationSupportDirectory, error);
    }
    
    return [self fileURLWithPath:archivePath isDirectory:NO];
}

@end
