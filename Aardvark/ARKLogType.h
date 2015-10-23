//
//  ARKLogType.h
//  Aardvark
//
//  Created by Evan Kimia on 10/22/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, ARKLogType) {
    /// Default log type.
    ARKLogTypeDefault,
    /// Marks the beginning or end of a task.
    ARKLogTypeSeparator,
    /// Marks that the log represents an error.
    ARKLogTypeError,
    /// Marks a log that has a screenshot attached.
    ARKLogTypeScreenshot,
};
