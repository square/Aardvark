//
//  ARKEmailBugReportConfiguration.m
//  Aardvark
//
//  Created by Nick Entin on 4/14/18.
//  Copyright 2018 Square, Inc.
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

#import "ARKEmailBugReportConfiguration.h"
#import "ARKEmailBugReportConfiguration_Protected.h"


@interface ARKEmailBugReportConfiguration ()

@property (nonatomic, readwrite) BOOL includesScreenshot;
@property (nonatomic, readwrite) BOOL includesViewHierarchyDescription;

@end


@implementation ARKEmailBugReportConfiguration

- (instancetype)initWithScreenshot:(BOOL)includesScreenshot viewHierarchyDescription:(BOOL)includesViewHierarchyDescription;
{
    self = [super init];
    
    _prefilledEmailSubject = @"";
    _logStores = @[];
    _includesScreenshot = includesScreenshot;
    _includesViewHierarchyDescription = includesViewHierarchyDescription;
    _additionalAttachments = @[];
    
    return self;
}

- (void)excludeScreenshot;
{
    self.includesScreenshot = NO;
}

- (void)excludeViewHierarchyDescription;
{
    self.includesViewHierarchyDescription = NO;
}

@end
