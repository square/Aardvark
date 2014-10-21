//
//  ARKLogHandler.h
//  Aardvark
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogController;
@class ARKLogMessage;


@protocol ARKLogHandler <NSObject>

/// Called on a background operation queue when logs are appended to the log controller.
- (void)logController:(ARKLogController *)logController didAppendLogMessage:(ARKLogMessage *)logMessage;

@end
