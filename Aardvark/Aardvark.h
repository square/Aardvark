//
//  Aardvark.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, ARKLogType) {
    /// Default log type.
    ARKLogTypeDefault,
    /// Marks the beginning or end of a task.
    ARKLogTypeSeparator,
    /// Marks that the log represents an error.
    ARKLogTypeError,
};


// Set this define to 0 after importing this header to turn off logging.
#define AARDVARK_LOG_ENABLED 1


OBJC_EXTERN void ARKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
OBJC_EXTERN void ARKTypeLog(ARKLogType type, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
OBJC_EXTERN void ARKLogScreenshot();


@protocol ARKBugReporter;


@interface Aardvark : NSObject

/// Sets up bug reporting with a ARKEmailBugReporter. Bug reports can be filed by pressing and holding with two fingers. Bug reports are sent over email to recipientAddress.
+ (void)setupBugReportingWithRecipientEmailAddress:(NSString *)recipientAddress;

/// Sets up bug reporting with the passed in bug reporter.
+ (void)setupBugReportingWithReporter:(id <ARKBugReporter>)bugReporter;

@end
