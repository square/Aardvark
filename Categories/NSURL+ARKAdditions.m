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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    NSString *archivePath = [[applicationSupportDirectory stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier] stringByAppendingPathComponent:filename];
    
    return [self fileURLWithPath:archivePath isDirectory:NO];
}

@end
