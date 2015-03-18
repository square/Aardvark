//
//  NSURL+ARKAdditions.h
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

@interface NSURL (ARKAdditions)

+ (NSURL *)ARK_fileURLWithApplicationSupportFilename:(NSString *)filename;

@end
