//
//  ARKEmailBugReporter.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKEmailBugReporter.h"

#import "ARKDefaultLogFormatter.h"
#import "ARKLogController.h"
#import "ARKLogMessage.h"


NSString *const ARKScreenshotFlashAnimationKey = @"ScreenshotFlashAnimation";


@interface ARKInvisibleView : UIView
@end


@interface ARKEmailBugReporter () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) UIView *whiteScreen;

@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic, strong) UIWindow *emailComposeWindow;

@property (nonatomic, copy) NSMutableSet *logControllers;

@end


@implementation ARKEmailBugReporter

#pragma mark - Class Methods

+ (ARKEmailBugReporter *)emailBugReporterWithEmailAddress:(NSString *)emailAddress;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = emailAddress;
    
    return bugReporter;
}

+ (ARKEmailBugReporter *)emailBugReporterWithEmailAddress:(NSString *)emailAddress prefilledEmailBody:(NSString *)prefilledEmailBody;
{
    ARKEmailBugReporter *bugReporter = [ARKEmailBugReporter new];
    bugReporter.bugReportRecipientEmailAddress = emailAddress;
    bugReporter.prefilledEmailBody = prefilledEmailBody;
    
    return bugReporter;
}

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
                           @"System version: %@\n", [[UIDevice currentDevice] systemVersion]];
    
    _logFormatter = [ARKDefaultLogFormatter new];
    _numberOfRecentErrorLogsToIncludeInBugReportBodyWhenAttachmentsAreAvailable = 3;
    _numberOfRecentErrorLogsToIncludeInBugReportBodyWhenAttachmentsAreUnavailable = 15;
    _emailComposeWindowLevel = UIWindowLevelStatusBar + 3.0;
    
    _logControllers = [NSMutableSet new];
    
    return self;
}

#pragma mark - ARKBugReporter

- (void)composeBugReport;
{
    NSAssert(self.bugReportRecipientEmailAddress.length, @"Attempting to compose a bug report without a recipient email address.");
    NSAssert(self.logControllers.count > 0, @"Attempting to compose a bug report without logs.");
    
    if (!self.whiteScreen) {
        // Take a screenshot.
        ARKLogScreenshot();
        
        // Flash the screen to simulate a screenshot being taken.
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        self.whiteScreen = [[UIView alloc] initWithFrame:keyWindow.frame];
        self.whiteScreen.layer.opacity = 0.0f;
        self.whiteScreen.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        [keyWindow addSubview:self.whiteScreen];
        
        CAKeyframeAnimation *screenFlash = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        screenFlash.duration = 0.8;
        screenFlash.values = @[@0.0, @0.8, @1.0, @0.9, @0.8, @0.7, @0.6, @0.5, @0.4, @0.3, @0.2, @0.1, @0.0];
        screenFlash.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        screenFlash.delegate = self;
        
        // Start the screen flash animation. Once this is done we'll fire up the bug reporter.
        [self.whiteScreen.layer addAnimation:screenFlash forKey:ARKScreenshotFlashAnimationKey];
    }
}

- (void)addLogController:(ARKLogController *)logController;
{
    NSAssert(self.mailComposeViewController == nil, @"Can not add a log controller while a bug is being composed.");
    
    [self.logControllers addObject:[NSValue valueWithNonretainedObject:logController]];
}
- (void)removeLogController:(ARKLogController *)logController;
{
    NSAssert(self.mailComposeViewController == nil, @"Can not add a remove a controller while a bug is being composed.");
    
    [self.logControllers removeObject:[NSValue valueWithNonretainedObject:logController]];
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
{
    [self.whiteScreen removeFromSuperview];
    self.whiteScreen = nil;
    
    /*
     iOS 8 often fails to transfer the keyboard from a focused text field to a UIAlertView's text field.
     Transfer first responder to an invisble view when a debug screenshot is captured to make bug filing itself bug-free.
     */
    [self _stealFirstResponder];
    
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
        
        if ([MFMailComposeViewController canSendMail]) {
            self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
            
            [self.mailComposeViewController setToRecipients:@[self.bugReportRecipientEmailAddress]];
            [self.mailComposeViewController setSubject:bugTitle];
            
            NSMutableString *emailBody = [NSMutableString stringWithFormat:@"%@\n", self.prefilledEmailBody];
            
            for (NSValue *logControllerValue in self.logControllers) {
                ARKLogController *logController = logControllerValue.nonretainedObjectValue;
                NSArray *logMessages = logController.allLogMessages;
                
                NSString *screenshotFileName = [NSLocalizedString(@"screenshot", @"File name of a screenshot") stringByAppendingPathExtension:@"png"];
                NSString *logsFileName = [NSLocalizedString(@"logs", @"File name for plaintext logs") stringByAppendingPathExtension:@"txt"];
                if (logController.name.length) {
                    [emailBody appendFormat:@"%@:\n", logController.name];
                    screenshotFileName = [logController.name stringByAppendingFormat:@"_%@", screenshotFileName];
                    logsFileName = [logController.name stringByAppendingFormat:@"_%@", logsFileName];
                }
                
                NSString *recentErrorLogs = [self.logFormatter recentErrorLogMessagesAsPlainText:logMessages count:self.numberOfRecentErrorLogsToIncludeInBugReportBodyWhenAttachmentsAreAvailable];
                if (recentErrorLogs.length) {
                    [emailBody appendFormat:@"%@\n", recentErrorLogs];
                }
                
                NSData *mostRecentImage = [self.logFormatter mostRecentImageAsPNG:logMessages];
                if (mostRecentImage.length) {
                    [self.mailComposeViewController addAttachmentData:[self.logFormatter mostRecentImageAsPNG:logMessages] mimeType:@"image/png" fileName:screenshotFileName];
                }
                
                NSData *formattedLogs = [self.logFormatter formattedLogMessagesAsData:logMessages];
                if (formattedLogs.length) {
                    [self.mailComposeViewController addAttachmentData:[self.logFormatter formattedLogMessagesAsData:logMessages] mimeType:@"text/plain" fileName:logsFileName];
                }
            }
            
            [self.mailComposeViewController setMessageBody:emailBody isHTML:NO];
            
            self.mailComposeViewController.mailComposeDelegate = self;
            
            [self _showEmailComposeWindow];
        } else {
            NSMutableString *emailBody = [NSMutableString new];
            for (NSValue *logControllerValue in self.logControllers) {
                ARKLogController *logController = logControllerValue.nonretainedObjectValue;
                NSArray *logMessages = logController.allLogMessages;
                
                [emailBody appendFormat:@"%@\n%@\n", self.prefilledEmailBody, [self.logFormatter recentErrorLogMessagesAsPlainText:logMessages count:self.numberOfRecentErrorLogsToIncludeInBugReportBodyWhenAttachmentsAreUnavailable]];
            }
            
            NSURL *composeEmailURL = [self _emailURLWithRecipients:@[self.bugReportRecipientEmailAddress] CC:@"" subject:bugTitle body:emailBody];
            if (composeEmailURL != nil) {
                [[UIApplication sharedApplication] openURL:composeEmailURL];
            }
        }
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
    UIAlertView *bugTitleCaptureAlert = [[UIAlertView alloc] initWithTitle:@"What Went Wrong?" message:@"Please briefly summarize the issue you just encountered. You’ll be asked for more details later." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Compose Report", nil];
    bugTitleCaptureAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *bugTitleTextField = [bugTitleCaptureAlert textFieldAtIndex:0];
    bugTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    bugTitleTextField.autocorrectionType = UITextAutocorrectionTypeYes;
    bugTitleTextField.spellCheckingType = UITextSpellCheckingTypeYes;
    bugTitleTextField.returnKeyType = UIReturnKeyDone;
    
    [bugTitleCaptureAlert show];
}

- (void)_showEmailComposeWindow;
{
    [self.mailComposeViewController beginAppearanceTransition:YES animated:YES];
    
    self.emailComposeWindow.rootViewController = self.mailComposeViewController;
    [self.emailComposeWindow addSubview:self.mailComposeViewController.view];
    [self.emailComposeWindow makeKeyAndVisible];
    
    [self.mailComposeViewController endAppearanceTransition];
}

- (void)_dismissEmailComposeWindow;
{
    [self.mailComposeViewController beginAppearanceTransition:NO animated:YES];
    
    [self.mailComposeViewController.view removeFromSuperview];
    self.emailComposeWindow.rootViewController = nil;
    self.emailComposeWindow = nil;
    
    [self.mailComposeViewController endAppearanceTransition];
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
