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

- (void)logController:(ARKLogController *)logController didAppendLogMessage:(ARKLogMessage *)logMessage;

@end
