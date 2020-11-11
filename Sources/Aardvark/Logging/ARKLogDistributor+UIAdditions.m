//
//  ARKLogDistributor+UIAdditions.m
//  Aardvark
//
//  Created by Dan Federman on 7/25/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
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

#import "ARKLogDistributor+UIAdditions.h"


@implementation ARKLogDistributor (UIAdditions)

#pragma mark - Public Methods - Appending Logs

- (void)logScreenshot;
{
    UIImage *screenshot = nil;
    
    @try {
        CGRect const screenBounds = [UIScreen mainScreen].bounds;
        UIGraphicsBeginImageContextWithOptions(screenBounds.size, NO, 0.0);
        for (UIWindow *const window in [UIApplication sharedApplication].windows) {
            [window drawViewHierarchyInRect:screenBounds afterScreenUpdates:NO];
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
