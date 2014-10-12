//
//  SampleLogger.h
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogger.h>


@interface SampleLogger : NSObject <ARKLogger>

- (instancetype)initWithLogController:(ARKLogController *)logController;

@end
