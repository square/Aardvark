//
//  Copyright © 2020 Square, Inc. All rights reserved.
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

//! Project version number for AardvarkMailUI.
FOUNDATION_EXPORT double AardvarkMailUIVersionNumber;

//! Project version string for AardvarkMailUI.
FOUNDATION_EXPORT const unsigned char AardvarkMailUIVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AardvarkMailUI/PublicHeader.h>

#if SWIFT_PACKAGE
#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReportConfiguration.h"
#else
#import <AardvarkMailUI/ARKEmailBugReporter.h>
#import <AardvarkMailUI/ARKEmailBugReportConfiguration.h>
#endif
