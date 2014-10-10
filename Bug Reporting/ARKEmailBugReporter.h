//
//  ARKEmailBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "ARKBugReporter.h"
#import "ARKLogFormatter.h"


/// Allows the user to trigger bug reports by making a two-finger press and hold gesture. Logs are sent out via email.
@interface ARKEmailBugReporter : NSObject <ARKBugReporter>

/// Convenience method to create a bug reporter with an email address.
+ (instancetype)emailBugReporterWithEmailAddress:(NSString *)emailAddress;

/// Convenience method to create a bug reporter with an email address and custom prefilledEmailBody.
+ (instancetype)emailBugReporterWithEmailAddress:(NSString *)emailAddress prefilledEmailBody:(NSString *)prefilledEmailBody;

/// The email address to which bug reports will be sent. Must be set before composeBugReportWithLogs: is called.
@property (nonatomic, copy, readwrite) NSString *bugReportRecipientEmailAddress;

/// The email body that will be presented to the user when they compose a report.
@property (nonatomic, copy, readwrite) NSString *prefilledEmailBody;

/// The formatter used to prepare the log for entry into an email. Defaults to a vanilla instance of ARKDefaultLogFormatter.
@property (nonatomic, copy, readwrite) id <ARKLogFormatter> logFormatter;

/// The window level for the email composer on iOS 7 or later. Defaults to UIWindowLevelStatusBar + 3.0.
@property (nonatomic, assign, readwrite) UIWindowLevel emailComposeWindowLevel;

@end
