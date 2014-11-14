//
//  SampleCrashlyticsLogConsumer.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/16/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogMessage.h>
#import <Crashlytics/Crashlytics.h>

#import "SampleCrashlyticsLogConsumer.h"


@implementation SampleCrashlyticsLogConsumer

- (void)consumeLogMessage:(ARKLogMessage *)logMessage;
{
    CLSLog(@"%@", logMessage.text);
}

@end
