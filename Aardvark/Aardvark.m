//
//  Aardvark.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright 2014 Square, Inc.
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

#import <CoreAardvark/AardvarkDefines.h>
#import <CoreAardvark/ARKLogDistributor.h>

#import "Aardvark.h"

#import "UIApplication+ARKAdditions.h"


@implementation Aardvark

#pragma mark - Class Methods

+ (ARKEmailBugReporter *)addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:(NSString *)emailAddress;
{
    ARKCheckCondition([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:)], nil, @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    ARKLogStore *logStore = [ARKLogDistributor defaultDistributor].defaultLogStore;
    ARKEmailBugReporter *bugReporter = [[ARKEmailBugReporter alloc] initWithEmailAddress:emailAddress logStore:logStore];
    
    [[UIApplication sharedApplication] ARK_addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter:bugReporter];
    
    return bugReporter;
}

+ (id)addBugReporter:(id <ARKBugReporter>)bugReporter triggeringGestureRecognizerClass:(Class)gestureRecognizerClass;
{
    ARKCheckCondition([[UIApplication sharedApplication] respondsToSelector:@selector(ARK_addBugReporter:triggeringGestureRecognizerClass:)], nil, @"Add -ObjC to your project's Other Linker Flags to use %s", __PRETTY_FUNCTION__);
    
    return [[UIApplication sharedApplication] ARK_addBugReporter:bugReporter triggeringGestureRecognizerClass:gestureRecognizerClass];
}

@end
