//
//  ARKLogObserver.h
//  CoreAardvark
//
//  Created by Dan Federman on 10/8/14.
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

#import <Foundation/Foundation.h>


@class ARKLogDistributor;
@class ARKLogMessage;


NS_ASSUME_NONNULL_BEGIN


@protocol ARKLogObserver <NSObject>

/// The log distributor that distributes logs to this observer.
@property (weak, nullable) ARKLogDistributor *logDistributor;

/// Called on a background operation queue when logs are appended to the log distributor.
- (void)observeLogMessage:(ARKLogMessage *)logMessage;

@end


NS_ASSUME_NONNULL_END
