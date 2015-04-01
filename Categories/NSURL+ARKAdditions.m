//
//  NSURL+ARKAdditions.m
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "NSURL+ARKAdditions.h"


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
