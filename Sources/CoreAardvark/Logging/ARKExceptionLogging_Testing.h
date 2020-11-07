//
//  ARKExceptionLogging_Testing.h
//  Aardvark
//
//  Created by Nick Entin on 9/28/18.
//  Copyright 2018 Square, Inc.
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


typedef NSUncaughtExceptionHandler *_Nullable (*ARKUncaughtExceptionHandlerGetter)(void);
OBJC_EXTERN ARKUncaughtExceptionHandlerGetter _Nonnull ARKGetUncaughtExceptionHandler;

typedef void (*ARKUncaughtExceptionHandlerSetter)(NSUncaughtExceptionHandler *_Nullable);
OBJC_EXTERN ARKUncaughtExceptionHandlerSetter _Nonnull ARKSetUncaughtExceptionHandler;

OBJC_EXTERN void ARKHandleUncaughtException(NSException *_Nonnull exception);

OBJC_EXTERN NSUncaughtExceptionHandler *_Nullable ARKPreviousUncaughtExceptionHandler;

OBJC_EXTERN NSMutableArray *_Nullable ARKUncaughtExceptionLogDistributors;
