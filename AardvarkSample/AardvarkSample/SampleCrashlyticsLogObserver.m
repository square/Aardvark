//
//  SampleCrashlyticsLogObserver.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/16/14.
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

#import <Aardvark/ARKLogMessage.h>

#import "SampleCrashlyticsLogObserver.h"


@implementation SampleCrashlyticsLogObserver

@synthesize logDistributor;

#pragma mark - ARKLogObserver

- (void)observeLogMessage:(ARKLogMessage *)logMessage;
{
    // If we were linking Crashlytics, we'd just uncomment the following line to forward the log to Crashlytics:
//    CLSLog(@"%@", logMessage.text);
}

@end
