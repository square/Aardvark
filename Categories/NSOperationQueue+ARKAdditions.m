//
//  NSOperationQueue+ARKAdditions.m
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "NSOperationQueue+ARKAdditions.h"


@implementation NSOperationQueue (ARKAdditions)

- (void)performOperationWithBlock:(dispatch_block_t)block waitUntilFinished:(BOOL)wait;
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    [self addOperations:@[blockOperation] waitUntilFinished:wait];
}

@end
