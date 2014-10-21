//
//  ARKLogFormatter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@class ARKLogMessage;


@protocol ARKLogFormatter <NSObject>

@required

/// Return a string that represents the log.
- (NSString *)formattedLogMessage:(ARKLogMessage *)logMessage;

@end
