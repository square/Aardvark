//
//  ARKLogObserver.h
//  Aardvark
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogDistributor;
@class ARKLogMessage;


@protocol ARKLogObserver <NSObject>

/// The log distributor that distributes logs to this observer.
@property (atomic, weak, readwrite) ARKLogDistributor *logDistributor;

/// Called on a background operation queue when logs are appended to the log distributor.
- (void)observeLogMessage:(ARKLogMessage *)logMessage;

@end
