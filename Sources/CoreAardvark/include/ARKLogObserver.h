//
//  Copyright 2014 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import Foundation;


@class ARKLogDistributor;
@class ARKLogMessage;


@protocol ARKLogObserver <NSObject>

/// The log distributor that distributes logs to this observer.
@property (nullable, weak) ARKLogDistributor *logDistributor;

/// Called on a background operation queue when logs are appended to the log distributor.
- (void)observeLogMessage:(nonnull ARKLogMessage *)logMessage;

@optional
/// Called to indicate that the observer should finish processing any pending logs in preparation for the app execution
/// terminating. Any asynchronous tasks should be prioritized and completed before calling the completion handler.
- (void)processAllPendingLogsWithCompletionHandler:(nonnull dispatch_block_t)completionHandler;

@end
