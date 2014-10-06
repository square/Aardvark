//
//  UIActivityViewController+ARKAdditions.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "UIActivityViewController+ARKAdditions.h"


@implementation UIActivityViewController (ARKAdditions)

+ (instancetype)newAardvarkActivityViewControllerWithItems:(NSArray *)items;
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeMessage, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypeAssignToContact]];
    
    return activityViewController;
}

@end
