//
//  ARKEmailBugReporter_Testing.h
//  Aardvark
//
//  Created by Dan Federman on 10/20/14.
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

#import <Aardvark/ARKEmailBugReporter.h>


@interface ARKEmailBugReporter ()

- (nonnull NSString *)_recentErrorLogMessagesAsPlainText:(nonnull NSArray *)logMessages count:(NSUInteger)errorLogsToInclude;

@end
