//
//  ARKEmailBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <Aardvark/ARKBugReporter.h>
#import <MessageUI/MessageUI.h>


@class ARKLogController;
@protocol ARKLogFormatter;


/// Composes a bug report that is sent via email.
@interface ARKEmailBugReporter : NSObject <ARKBugReporter>

- (instancetype)initWithEmailAddress:(NSString *)emailAddress logController:(ARKLogController *)logController;

/// The email address to which bug reports will be sent. Must be set before composeBugReportWithLogs: is called.
@property (nonatomic, copy, readonly) NSString *bugReportRecipientEmailAddress;

/// The email body that will be presented to the user when they compose a report.
@property (nonatomic, copy, readwrite) NSString *prefilledEmailBody;

/// The formatter used to prepare the log for entry into an email. Defaults to a vanilla instance of ARKDefaultLogFormatter.
@property (nonatomic, strong, readwrite) id <ARKLogFormatter> logFormatter;

/// Controls the number of recent error logs per log controller to include in the email body of a bug report composed in a mail client that allows attachments. Defaults to 3.
@property (nonatomic, assign, readwrite) NSUInteger numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreAvailable;

/// Controls the number of recent error logs per log controller to include in the email body of a bug report composed in a mail client that does not allow attachments. Defaults to 15.
@property (nonatomic, assign, readwrite) NSUInteger numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreUnavailable;

/// The window level for the email composer on iOS 7 or later. Defaults to UIWindowLevelStatusBar + 3.0.
@property (nonatomic, assign, readwrite) UIWindowLevel emailComposeWindowLevel;

@end
