//
//  Copyright 2015 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import Foundation;


@interface NSFileHandle (ARKAdditions)

/// Should Aardvark stop logging after catching a `NSException`?
/// Default: `NO` to avoid changing API behavior within the same major (as in major.minor.patch versioning) version
+ (void)ARK_setPreventWritesAfterException:(BOOL)preventWritesAfterException;

@end
