//
//  ARKDataArchive_Testing.h
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "ARKDataArchive.h"


@interface ARKDataArchive (Private)

@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;

@end
