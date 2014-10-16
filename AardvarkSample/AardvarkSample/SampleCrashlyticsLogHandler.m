//
//  SampleCrashlyticsLogHandler.m
//  AardvarkSample
//
//  Created by Dan Federman on 10/16/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogMessage.h>
#import <Crashlytics/Crashlytics.h>

#import "SampleCrashlyticsLogHandler.h"


@implementation SampleCrashlyticsLogHandler

- (void)logController:(ARKLogController *)logController didAppendLogMessage:(ARKLogMessage *)logMessage;
{
    CLSLog(@"%@", logMessage.text);
}

@end
