//
//  ARKLogDistributor_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 10/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKLogDistributor (Private)

- (NSMutableSet *)logObservers;
- (NSOperationQueue *)logDistributingQueue;

@end
