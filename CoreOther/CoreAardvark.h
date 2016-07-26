//
//  CoreAardvark-iOS.h
//  CoreAardvark-iOS
//
//  Created by Dan Federman on 7/25/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for CoreAardvark-iOS.
FOUNDATION_EXPORT double CoreAardvark_iOSVersionNumber;

//! Project version string for CoreAardvark-iOS.
FOUNDATION_EXPORT const unsigned char CoreAardvark_iOSVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CoreAardvark_iOS/PublicHeader.h>

#if COCOAPODS
#import <Aardvark/AardvarkDefines.h>
#import <Aardvark/ARKLogDistributor.h>
#import <Aardvark/ARKLogMessage.h>
#import <Aardvark/ARKLogObserver.h>
#import <Aardvark/ARKLogStore.h>
#import <Aardvark/ARKLogTypes.h>
#else
#import <CoreAardvark/AardvarkDefines.h>
#import <CoreAardvark/ARKLogDistributor.h>
#import <CoreAardvark/ARKLogMessage.h>
#import <CoreAardvark/ARKLogObserver.h>
#import <CoreAardvark/ARKLogStore.h>
#import <CoreAardvark/ARKLogTypes.h>
#endif
