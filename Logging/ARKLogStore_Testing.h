//
//  ARKLogStore_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 11/13/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface ARKLogStore (Private)

- (NSMutableArray *)logMessages;
- (NSOperationQueue *)logConsumingQueue;

- (NSArray *)_persistedLogs;
- (void)_persistLogs_inLogConsumingQueue;
- (void)_trimLogs_inLogConsumingQueue;
- (NSArray *)_trimmedLogsToPersist_inLogConsumingQueue;

@end
