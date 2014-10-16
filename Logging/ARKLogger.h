//
//  ARKLogger.h
//  Aardvark
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogController;


@protocol ARKLogger <NSObject>

/// The log controller to which the logger will log. Weak reference prevents retain cycle.
@property (nonatomic, weak, readonly) ARKLogController *logController;

@end
