//
//  ARKExceptionLogging.h
//  Aardvark
//
//  Created by Nick Entin on 9/7/17.
//  Copyright 2017 Square, Inc.
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


/// Enables logging uncaught exceptions. Calls into previously-set uncaught exception handler after logging if one has been set.
OBJC_EXTERN void ARKEnableLogOnUncaughtException(void);

/// Disables logging uncaught exceptions. Restores the uncaught exception handler set prior to enabling Aardvark exception logging if one was set.
OBJC_EXTERN void ARKDisableLogOnUncaughtException(void);
