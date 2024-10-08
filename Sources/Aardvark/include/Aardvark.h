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

@import UIKit;


//! Project version number for Aardvark-iOS.
FOUNDATION_EXPORT double Aardvark_iOSVersionNumber;

//! Project version string for Aardvark-iOS.
FOUNDATION_EXPORT const unsigned char Aardvark_iOSVersionString[];

#if SWIFT_PACKAGE
#import "ARKLogDistributor+UIAdditions.h"
#import "ARKScreenshotLogging.h"
#else
#import <Aardvark/ARKLogDistributor+UIAdditions.h>
#import <Aardvark/ARKScreenshotLogging.h>
#endif
