//
//  ARKEmailBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import <MessageUI/MessageUI.h>


@interface ARKEmailBugReporter : NSObject

/// The email address to which bug reports will be sent. Must be set before composeBugReportWithLogs: is called.
@property (nonatomic, copy, readwrite) NSString *bugReportRecipientEmailAddress;

/// The email body that will be presented to the user when they compose a report.
@property (nonatomic, copy, readwrite) NSString *prefilledEmailBody;

/// The window level for the email composer on iOS 7 or later. Defaults to UIWindowLevelStatusBar + 3.0.
@property (nonatomic, assign, readwrite) UIWindowLevel emailComposeWindowLevel;

- (void)composeBugReportWithLogs:(NSArray *)logs;

@end
