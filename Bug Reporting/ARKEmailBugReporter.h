//
//  ARKEmailBugReporter.h
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
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

#import <Aardvark/ARKBugReporter.h>
#import <MessageUI/MessageUI.h>


@class ARKEmailBugReporter;
@class ARKLogStore;
@protocol ARKLogFormatter;


NS_ASSUME_NONNULL_BEGIN


@protocol ARKEmailBugReporterEmailBodyAdditionsDelegate <NSObject>

@required

/// Called on the main thread when a bug is filed. The key/value pairs in the returned dictionary will be appended to the bug report below the prefilledEmailBody.
- (nullable NSDictionary *)emailBodyAdditionsForEmailBugReporter:(ARKEmailBugReporter *)emailBugReporter;

@end


/// Composes a bug report that is sent via email.
@interface ARKEmailBugReporter : NSObject <ARKBugReporter>

- (instancetype)initWithEmailAddress:(NSString *)emailAddress logStore:(ARKLogStore *)logStore;

- (instancetype)initWithEmailAddresses:(NSArray<NSString *> *)emailAddress logStore:(ARKLogStore *)logStore;

/// The email addresses to which bug reports will be sent. Must be set before composeBugReport is called.
@property (nonatomic, copy) NSArray<NSString *> *bugReportRecipientEmailAddresses;

/// The email body that will be presented to the user when they compose a report.
@property (nonatomic, copy) NSString *prefilledEmailBody;

/// The email body delegate, responsible for providing key/value pairs to include in the bug report at the time the bug is filed.
@property (nullable, nonatomic, weak) id <ARKEmailBugReporterEmailBodyAdditionsDelegate> emailBodyAdditionsDelegate;

/// The formatter used to prepare the log for entry into an email. Defaults to a vanilla instance of ARKDefaultLogFormatter.
@property (nonatomic) id <ARKLogFormatter> logFormatter;

/// Controls the number of recent error logs per log distributor to include in the email body of a bug report composed in a mail client that allows attachments. Defaults to 3.
@property (nonatomic) NSUInteger numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreAvailable;

/// Controls the number of recent error logs per log distributor to include in the email body of a bug report composed in a mail client that does not allow attachments. Defaults to 15.
@property (nonatomic) NSUInteger numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreUnavailable;

/// The window level for the email composer on iOS 7 or later. Defaults to UIWindowLevelStatusBar + 3.0.
@property (nonatomic) UIWindowLevel emailComposeWindowLevel;

/// Returns formatted log messages as NSData.
- (NSData *)formattedLogMessagesAsData:(NSArray *)logMessages;

/// Returns the MIME type of the data returned by formattedLogMessagesAsData:. MIME types are as specified by the IANA: http://www.iana.org/assignments/media-types/
- (NSString *)formattedLogMessagesDataMIMEType;

/// Returns the extension for the log attachments.
- (NSString *)formattedLogMessagesAttachmentExtension;

@end


NS_ASSUME_NONNULL_END
