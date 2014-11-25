//
//  ARKLogStore_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKLogStore (Private)

- (NSMutableArray *)logMessages;
- (NSOperationQueue *)logObservingQueue;

- (NSArray *)_persistedLogs;
- (void)_persistLogs_inLogObservingQueue;
- (void)_trimLogs_inLogObservingQueue;
- (void)_trimmedLogsToPersist_inLogObservingQueue:(void (^)(NSArray *logsToPersist))completionHandler;

@end
