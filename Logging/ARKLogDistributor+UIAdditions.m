//
//  ARKLogDistributor+UIAdditions.m
//  Aardvark
//
//  Created by Dan Federman on 7/25/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//

#import "ARKLogDistributor+UIAdditions.h"


@implementation ARKLogDistributor (UIAdditions)

#pragma mark - Public Methods - Appending Logs

- (void)logScreenshot;
{
    UIImage *screenshot = nil;
    
    @try {
        UIWindow *const keyWindow = [[UIApplication sharedApplication] keyWindow];
        if ([keyWindow respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            // iOS 7 and later.
            CGRect const screenBounds = [UIScreen mainScreen].bounds;
            UIGraphicsBeginImageContextWithOptions(screenBounds.size, NO, 0.0);
            for (UIWindow *const window in [UIApplication sharedApplication].windows) {
                [window drawViewHierarchyInRect:screenBounds afterScreenUpdates:NO];
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(keyWindow.bounds.size, YES, 0.0);
            [keyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
        screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    @catch (NSException *exception) {
        [self logWithType:ARKLogTypeError userInfo:nil format:@"Screenshot capture failed due to %@", exception];
    }
    
    if (screenshot != nil) {
        NSString *logText = @"Screenshot Logged";
        [self logWithText:logText image:screenshot type:ARKLogTypeScreenshot userInfo:nil];
    }
}

@end
