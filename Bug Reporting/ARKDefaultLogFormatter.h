//
//  ARKLogFormatter.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogFormatter.h"


@interface ARKDefaultLogFormatter : NSObject <ARKLogFormatter>

/// The string that is prepended to error logs.
@property (nonatomic, copy, readwrite) NSString *errorLogPrefix;

/// The string that is prepended to separator logs.
@property (nonatomic, copy, readwrite) NSString *separatorLogPrefix;

@end
