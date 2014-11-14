//
//  NSOperationQueue+ARKAdditions.h
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface NSOperationQueue (ARKAdditions)

- (void)performOperationWithBlock:(dispatch_block_t)block waitUntilFinished:(BOOL)wait;

@end
