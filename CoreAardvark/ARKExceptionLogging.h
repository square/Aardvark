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

@class ARKLogDistributor;


/// Enables logging uncaught exceptions to the default log distributor. Calls into previously-set uncaught exception handler after logging if one has been set. Can be called from any thread.
OBJC_EXTERN void ARKEnableLogOnUncaughtException(void);

/// Enables logging uncaught exceptions to the specified log distributor. Calls into previously-set uncaught exception handler after logging if one has been set. Can be called from any thread.
OBJC_EXTERN void ARKEnableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor);

/// Disables logging uncaught exceptions to the default log distributor. Restores the uncaught exception handler set prior to enabling Aardvark exception logging if one was set. Can be called from any thread.
OBJC_EXTERN void ARKDisableLogOnUncaughtException(void);

/// Disables logging uncaught exceptions to the specified log distributor.  Restores the uncaught exception handler set prior to enabling Aardvark exception logging if one was set. Can be called from any thread.
OBJC_EXTERN void ARKDisableLogOnUncaughtExceptionToLogDistributor(ARKLogDistributor *_Nonnull logDistributor);
