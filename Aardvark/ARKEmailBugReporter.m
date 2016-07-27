//
//  ARKEmailBugReporter.m
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

#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReporter_Testing.h"

#import "AardvarkDefines.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKScreenshotLogging.h"
#import "ARKLogStore.h"
#import "ARKLogMessage.h"


NSString *const ARKScreenshotFlashAnimationKey = @"ScreenshotFlashAnimation";


@interface ARKInvisibleView : UIView
@end


@interface ARKEmailBugReporter () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic) UIView *screenFlashView;

@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) UIWindow *emailComposeWindow;
@property (nonatomic, weak) UIWindow *previousKeyWindow;

@property (nonatomic, copy) NSMutableArray *mutableLogStores;

@property (nonatomic) BOOL attachScreenshotToNextBugReport;

@end


@implementation ARKEmailBugReporter

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _prefilledEmailBody = [NSString stringWithFormat:@"Reproduction Steps:\n"
                           @"1. \n"
                           @"2. \n"
                           @"3. \n"
                           @"\n"
                           @"System version: %@", [[UIDevice currentDevice] systemVersion]];
    
    _logFormatter = [ARKDefaultLogFormatter new];
    _numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreAvailable = 3;
    _numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreUnavailable = 15;
    _emailComposeWindowLevel = UIWindowLevelStatusBar + 3.0;
    
    _mutableLogStores = [NSMutableArray new];
    
    return self;
}

- (instancetype)initWithEmailAddress:(NSString *)emailAddress logStore:(ARKLogStore *)logStore;
{
    self = [self init];
    
    _bugReportRecipientEmailAddress = [emailAddress copy];
    [self addLogStores:@[logStore]];
    
    return self;
}

#pragma mark - ARKBugReporter

- (void)composeBugReport;
{
    [self composeBugReportWithScreenshot:YES];
}

- (void)composeBugReportWithoutScreenshot;
{
    [self composeBugReportWithScreenshot:NO];
}

- (void)composeBugReportWithScreenshot:(BOOL)attachScreenshot;
{
    ARKCheckCondition(self.bugReportRecipientEmailAddress.length, , @"Attempting to compose a bug report without a recipient email address.");
    ARKCheckCondition(self.mutableLogStores.count > 0, , @"Attempting to compose a bug report without logs.");
    
    self.attachScreenshotToNextBugReport = attachScreenshot;
    
    if (attachScreenshot && !self.screenFlashView) {
        // Take a screenshot.
        ARKLogScreenshot();
        
        // Flash the screen to simulate a screenshot being taken.
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        self.screenFlashView = [[UIView alloc] initWithFrame:keyWindow.frame];
        self.screenFlashView.layer.opacity = 0.0f;
        self.screenFlashView.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        [keyWindow addSubview:self.screenFlashView];
        
        CAKeyframeAnimation *screenFlash = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        screenFlash.duration = 0.8;
        screenFlash.values = @[@0.0, @0.8, @1.0, @0.9, @0.8, @0.7, @0.6, @0.5, @0.4, @0.3, @0.2, @0.1, @0.0];
        screenFlash.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        screenFlash.delegate = self;
        
        // Start the screen flash animation. Once this is done we'll fire up the bug reporter.
        [self.screenFlashView.layer addAnimation:screenFlash forKey:ARKScreenshotFlashAnimationKey];
    }
    else {
        [self _showBugTitleCaptureAlert];
    }
}

- (void)addLogStores:(NSArray *)logStores;
{
    ARKCheckCondition(self.mailComposeViewController == nil, , @"Can not add a log store while a bug is being composed.");
    
    for (ARKLogStore *logStore in logStores) {
        ARKCheckCondition([logStore isKindOfClass:[ARKLogStore class]], , @"Can not add a log store of class %@", NSStringFromClass([logStore class]));
        if ([self.mutableLogStores containsObject:logStore]) {
            [self.mutableLogStores removeObject:logStore];
        }
        
        [self.mutableLogStores addObject:logStore];
    }
}

- (void)removeLogStores:(NSArray *)logStores;
{
    ARKCheckCondition(self.mailComposeViewController == nil, , @"Can not add a remove a controller while a bug is being composed.");
    
    for (ARKLogStore *logStore in logStores) {
        ARKCheckCondition([logStore isKindOfClass:[ARKLogStore class]], , @"Can not remove a log store of class %@", NSStringFromClass([logStore class]));
    }
    
    for (ARKLogStore *logStore in logStores) {
        [self.mutableLogStores removeObject:logStore];
    }
}

- (NSArray *)logStores;
{
    return [self.mutableLogStores copy];
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
{
    [self.screenFlashView removeFromSuperview];
    self.screenFlashView = nil;
    
    [self _showBugTitleCaptureAlert];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _dismissEmailComposeWindow];
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
{
    if (alertView.firstOtherButtonIndex == buttonIndex) {
        NSString *bugTitle = [alertView textFieldAtIndex:0].text;
        
        [self _createBugReportWithTitle:bugTitle];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
{
    return [alertView textFieldAtIndex:0].text.length > 0;
}

#pragma mark - Properties

- (UIWindow *)emailComposeWindow;
{
    if (!_emailComposeWindow) {
        _emailComposeWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        if ([_emailComposeWindow respondsToSelector:@selector(tintColor)] /* iOS 7 or later */) {
            // The keyboard won't show up on iOS 6 with a high windowLevel, but iOS 7+ will.
            _emailComposeWindow.windowLevel = self.emailComposeWindowLevel;
        }
    }
    
    return _emailComposeWindow;
}

#pragma mark - Public Methods

- (NSData *)formattedLogMessagesAsData:(NSArray *)logMessages;
{
    NSMutableArray *formattedLogMessages = [NSMutableArray new];
    for (ARKLogMessage *logMessage in logMessages) {
        [formattedLogMessages addObject:[self.logFormatter formattedLogMessage:logMessage]];
    }
    
    return [[formattedLogMessages componentsJoinedByString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)formattedLogMessagesDataMIMEType;
{
    return @"text/plain";
}

- (NSString *)formattedLogMessagesAttachmentExtension;
{
    return @"txt";
}

#pragma mark - Private Methods

- (void)_stealFirstResponder;
{
    ARKInvisibleView *invisibleView = [ARKInvisibleView new];
    invisibleView.layer.opacity = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:invisibleView];
    [invisibleView becomeFirstResponder];
    [invisibleView removeFromSuperview];
}

- (void)_showBugTitleCaptureAlert;
{
    /*
     iOS 8 often fails to transfer the keyboard from a focused text field to a UIAlertView's text field.
     Transfer first responder to an invisble view when a debug screenshot is captured to make bug filing itself bug-free.
     */
    [self _stealFirstResponder];
    
    NSString * const title = NSLocalizedString(@"What Went Wrong?", @"Title text for alert asking user to describe a bug they just encountered");
    NSString * const message = NSLocalizedString(@"Please briefly summarize the issue you just encountered. You’ll be asked for more details later.", @"Subtitle text for alert asking user to describe a bug they just encountered");
    NSString * const composeReportButtonTitle = NSLocalizedString(@"Compose Report", @"Button title to compose bug report");
    NSString * const cancelButtonTitle = NSLocalizedString(@"Cancel", @"Button title to not compose a bug report");
    
    // iOS 8 and later
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:composeReportButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *textfield = [alertController.textFields firstObject];
            [self _createBugReportWithTitle:textfield.text];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleDefault handler:NULL]];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            [self _configureAlertTextfield:textField];
        }];
        
        UIViewController *const rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIViewController *const viewControllerToPresentAlertController = rootViewController.presentedViewController ?: rootViewController;
        [viewControllerToPresentAlertController presentViewController:alertController animated:YES completion:NULL];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:composeReportButtonTitle, nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        [self _configureAlertTextfield:textField];
        
        [alertView show];
    }
}

- (void)_configureAlertTextfield:(UITextField *)textField
{
    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textField.autocorrectionType = UITextAutocorrectionTypeYes;
    textField.spellCheckingType = UITextSpellCheckingTypeYes;
    textField.returnKeyType = UIReturnKeyDone;
}

- (void)_createBugReportWithTitle:(NSString *)title
{
    NSArray *logStores = [self.logStores copy];
    NSMapTable *logStoresToLogMessagesMap = [NSMapTable new];
    NSDictionary *emailBodyAdditions = [self.emailBodyAdditionsDelegate emailBodyAdditionsForEmailBugReporter:self];
    
    if ([MFMailComposeViewController canSendMail]) {
        self.mailComposeViewController = [MFMailComposeViewController new];
        
        [self.mailComposeViewController setToRecipients:@[self.bugReportRecipientEmailAddress]];
        [self.mailComposeViewController setSubject:title];
        
        for (ARKLogStore *logStore in logStores) {
            [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
                [logStoresToLogMessagesMap setObject:logMessages forKey:logStore];
                
                // Only attach data once all log messages have been retrieved.
                if (logStoresToLogMessagesMap.count == logStores.count) {
                    NSMutableString *emailBody = [self _prefilledEmailBodyWithEmailBodyAdditions:emailBodyAdditions];
                    
                    for (ARKLogStore *logStore in logStores) {
                        NSArray *logMessages = [logStoresToLogMessagesMap objectForKey:logStore];
                        
                        NSString *screenshotFileName = [NSLocalizedString(@"screenshot", @"File name of a screenshot") stringByAppendingPathExtension:@"png"];
                        NSString *logsFileName = [NSLocalizedString(@"logs", @"File name for logs attachments") stringByAppendingPathExtension:[self formattedLogMessagesAttachmentExtension]];
                        NSMutableString *emailBodyForLogStore = [NSMutableString new];
                        BOOL appendToEmailBody = NO;
                        
                        if (logStore.name.length) {
                            [emailBodyForLogStore appendFormat:@"%@:\n", logStore.name];
                            screenshotFileName = [logStore.name stringByAppendingFormat:@"_%@", screenshotFileName];
                            logsFileName = [logStore.name stringByAppendingFormat:@"_%@", logsFileName];
                        }
                        
                        NSString *recentErrorLogs = [self _recentErrorLogMessagesAsPlainText:logMessages count:self.numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreAvailable];
                        if (recentErrorLogs.length) {
                            [emailBodyForLogStore appendFormat:@"%@\n", recentErrorLogs];
                            appendToEmailBody = YES;
                        }
                        
                        if (appendToEmailBody) {
                            [emailBody appendString:emailBodyForLogStore];
                        }
                        
                        
                        if (self.attachScreenshotToNextBugReport) {
                            NSData *mostRecentImage = [self _mostRecentImageAsPNG:logMessages];
                            if (mostRecentImage.length) {
                                [self.mailComposeViewController addAttachmentData:mostRecentImage mimeType:@"image/png" fileName:screenshotFileName];
                            }
                        }
                        
                        NSData *formattedLogs = [self formattedLogMessagesAsData:logMessages];
                        if (formattedLogs.length) {
                            [self.mailComposeViewController addAttachmentData:formattedLogs mimeType:[self formattedLogMessagesDataMIMEType] fileName:logsFileName];
                        }
                    }
                    
                    [self.mailComposeViewController setMessageBody:emailBody isHTML:NO];
                    self.mailComposeViewController.mailComposeDelegate = self;
                    [self _showEmailComposeWindow];
                }
            }];
        }
        
    } else {
        for (ARKLogStore *logStore in logStores) {
            [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
                [logStoresToLogMessagesMap setObject:logMessages forKey:logStore];
                
                // Only append logs once all log messages have been retrieved.
                if (logStoresToLogMessagesMap.count == logStores.count) {
                    NSMutableString *emailBody = [self _prefilledEmailBodyWithEmailBodyAdditions:emailBodyAdditions];
                    
                    for (ARKLogStore *logStore in logStores) {
                        NSArray *logMessages = [logStoresToLogMessagesMap objectForKey:logStore];
                        [emailBody appendFormat:@"%@\n", [self _recentErrorLogMessagesAsPlainText:logMessages count:self.numberOfRecentErrorLogsToIncludeInEmailBodyWhenAttachmentsAreUnavailable]];
                    }
                    
                    NSURL *composeEmailURL = [self _emailURLWithRecipients:@[self.bugReportRecipientEmailAddress] CC:@"" subject:title body:emailBody];
                    if (composeEmailURL != nil) {
                        [[UIApplication sharedApplication] openURL:composeEmailURL];
                    }
                }
            }];
        }
    }
}

- (void)_showEmailComposeWindow;
{
    self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
    
    [self.mailComposeViewController beginAppearanceTransition:YES animated:YES];
    
    self.emailComposeWindow.rootViewController = self.mailComposeViewController;
    [self.emailComposeWindow addSubview:self.mailComposeViewController.view];
    [self.emailComposeWindow makeKeyAndVisible];
    
    [self.mailComposeViewController endAppearanceTransition];
}

- (void)_dismissEmailComposeWindow;
{
    // Actually dismiss the mail compose view controller.
    [self.mailComposeViewController beginAppearanceTransition:NO animated:YES];
    
    [self.mailComposeViewController.view removeFromSuperview];
    self.emailComposeWindow.rootViewController = nil;
    self.emailComposeWindow = nil;
    
    [self.mailComposeViewController endAppearanceTransition];
    
    static BOOL iOS9OrLater;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iOS9OrLater = [[UIDevice currentDevice].systemVersion compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending;
    });
    
    // Work around an iOS 9 bug where we don't get UIWindowDidBecomeKeyNotification when the mail compose view controller dismisses.
    if (iOS9OrLater) {
        [self.previousKeyWindow makeKeyAndVisible];
        self.previousKeyWindow = nil;
    }
}

- (NSMutableString *)_prefilledEmailBodyWithEmailBodyAdditions:(nullable NSDictionary *)emailBodyAdditions;
{
    NSMutableString *prefilledEmailBodyWithEmailBodyAdditions = [NSMutableString stringWithFormat:@"%@\n", self.prefilledEmailBody];
    
    if (emailBodyAdditions.count > 0) {
        for (NSString *emailBodyAdditionKey in emailBodyAdditions.allKeys) {
            [prefilledEmailBodyWithEmailBodyAdditions appendFormat:@"%@: %@\n", emailBodyAdditionKey, emailBodyAdditions[emailBodyAdditionKey]];
        }
    }
    
    // Add a newline to separate prefill email body and additions from what comes after.
    [prefilledEmailBodyWithEmailBodyAdditions appendString:@"\n"];

    return prefilledEmailBodyWithEmailBodyAdditions;
}

- (NSString *)_recentErrorLogMessagesAsPlainText:(NSArray *)logMessages count:(NSUInteger)errorLogsToInclude;
{
    NSMutableString *recentErrorLogs = [NSMutableString new];
    NSUInteger failuresFound = 0;
    for (ARKLogMessage *log in [logMessages reverseObjectEnumerator]) {
        if(log.type == ARKLogTypeError) {
            [recentErrorLogs appendFormat:@"%@\n", log];
            
            if(++failuresFound >= errorLogsToInclude) {
                break;
            }
        }
    }
    
    if (recentErrorLogs.length) {
        // Remove the final newline and create an immutable string.
        return [recentErrorLogs stringByReplacingCharactersInRange:NSMakeRange(recentErrorLogs.length - 1, 1) withString:@""];
    } else {
        return nil;
    }
}

- (NSData *)_mostRecentImageAsPNG:(NSArray *)logMessages;
{
    for (ARKLogMessage *logMessage in [logMessages reverseObjectEnumerator]) {
        if (logMessage.image) {
            return UIImagePNGRepresentation(logMessage.image);
        }
    }
    
    return nil;
}

- (NSURL *)_emailURLWithRecipients:(NSArray *)recipients CC:(NSString *)CCLine subject:(NSString *)subjectLine body:(NSString *)bodyText;
{
    NSArray *prefixes = @[@"sparrow://", @"googlegmail:///co", @"mailto:"];
    
    NSURL *URL = nil;
    for (NSString *prefix in prefixes) {
        URL = [self _emailURLWithPrefix:prefix recipients:recipients CC:CCLine subject:subjectLine body:bodyText];
        
        if (URL != nil) {
            break;
        }
    }
    
    return URL;
}

- (NSURL *)_emailURLWithPrefix:(NSString *)prefix recipients:(NSArray *)recipients CC:(NSString *)CCLine subject:(NSString *)subjectLine body:(NSString *)bodyText;
{
    NSString *recipientsEscapedString = [[recipients componentsJoinedByString:@","] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *toArgument = (recipients.count > 0) ? [NSString stringWithFormat:@"to=%@&", recipientsEscapedString] : @"";
    NSString *URLString = [NSString stringWithFormat:@"%@?%@cc=%@&subject=%@&body=%@",
                           prefix,
                           toArgument,
                           [CCLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [subjectLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [bodyText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *URL = [NSURL URLWithString:URLString];
    return [[UIApplication sharedApplication] canOpenURL:URL] ? URL : nil;
}


@end


@implementation ARKInvisibleView

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

@end
