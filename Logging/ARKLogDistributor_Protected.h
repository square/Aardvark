//
//  ARKLogDistributor_Protected.h
//  Aardvark
//
//  Created by Dan Federman on 3/30/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

@interface ARKLogDistributor (Protected)

- (void)waitUntilAllPendingLogsHaveBeenDistributed;

@end
