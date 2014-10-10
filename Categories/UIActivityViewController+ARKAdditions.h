//
//  UIActivityViewController+ARKAdditions.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface UIActivityViewController (ARKAdditions)

/// Creates an activity sheet that allows for sharing via AirDrop, email, copying to the pasteboard and printing.
+ (instancetype)ARK_newAardvarkActivityViewControllerWithItems:(NSArray *)items;

@end
