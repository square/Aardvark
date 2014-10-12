//
//  SampleTapLogger.h
//  AardvarkSample
//
//  Created by Dan Federman on 10/11/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKLogger.h>


@interface SampleTapLogger : NSObject <ARKLogger>

- (instancetype)initWithView:(UIView *)view logController:(ARKLogController *)logController;

@end
