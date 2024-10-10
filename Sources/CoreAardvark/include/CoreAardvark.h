//
//  Copyright © 2016 Square, Inc. All rights reserved.
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

@import UIKit;


//! Project version number for CoreAardvark-iOS.
FOUNDATION_EXPORT double CoreAardvark_iOSVersionNumber;

//! Project version string for CoreAardvark-iOS.
FOUNDATION_EXPORT const unsigned char CoreAardvark_iOSVersionString[];

#if SWIFT_PACKAGE
#import "AardvarkDefines.h"
#import "ARKDataArchive.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKLogDistributor.h"
#import "ARKLogging.h"
#import "ARKLogFormatter.h"
#import "ARKLogMessage.h"
#import "ARKLogObserver.h"
#import "ARKLogStore.h"
#import "ARKLogTypes.h"
#import "ARKExceptionLogging.h"
#else
#import <CoreAardvark/AardvarkDefines.h>
#import <CoreAardvark/ARKDataArchive.h>
#import <CoreAardvark/ARKDefaultLogFormatter.h>
#import <CoreAardvark/ARKLogDistributor.h>
#import <CoreAardvark/ARKLogging.h>
#import <CoreAardvark/ARKLogFormatter.h>
#import <CoreAardvark/ARKLogMessage.h>
#import <CoreAardvark/ARKLogObserver.h>
#import <CoreAardvark/ARKLogStore.h>
#import <CoreAardvark/ARKLogTypes.h>
#import <CoreAardvark/ARKExceptionLogging.h>
#endif
