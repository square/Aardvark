//
//  ARKEmailBugReporter.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKEmailBugReporter.h"

#import "ARKAardvarkLog.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKLogFormatter.h"


@interface ARKInvisibleView : UIView
@end


@interface ARKEmailBugReporter () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) id strongSelf;

@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic, strong) UIWindow *emailComposeWindow;

@property (nonatomic, strong) NSArray *logs;

@end


@implementation ARKEmailBugReporter

#pragma mark - Class Methods

+ (instancetype)allocWithZone:(struct _NSZone *)zone;
{
#if AARDVARK_LOG_ENABLED
    return [super allocWithZone:zone];
#else
    return nil;
#endif
}

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _prefilledEmailBody = [NSString stringWithFormat:@"Reproduction Steps:\n\
                           1. \n\
                           2. \n\
                           3. \n\
                           \n\
                           System version: %@\n", [[UIDevice currentDevice] systemVersion]];
    
    _logFormatter = [ARKDefaultLogFormatter new];
    _emailComposeWindowLevel = UIWindowLevelStatusBar + 3.0;
    
    return self;
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
            
            NSString *emailBody = [NSString stringWithFormat:@"%@\n%@", self.prefilledEmailBody, [self.logFormatter recentErrorLogsAsPlainText:self.logs count:3]];
            
            [self.mailComposeViewController setMessageBody:emailBody isHTML:NO];
            [self.mailComposeViewController addAttachmentData:[self.logFormatter mostRecentImageAsPNG:self.logs] mimeType:@"image/png" fileName:@"screenshot.png"];
            [self.mailComposeViewController addAttachmentData:[self.logFormatter formattedLogsAsData:self.logs] mimeType:@"text/plain" fileName:@"logs.txt"];
            
            self.mailComposeViewController.mailComposeDelegate = self;
            
            [self _showEmailComposeWindow];
        } else {
            NSString *emailBody = [NSString stringWithFormat:@"%@\n%@", self.prefilledEmailBody, [self.logFormatter recentErrorLogsAsPlainText:self.logs count:15]];
            
            NSURL *composeEmailURL = [self _emailURLWithRecipients:@[self.bugReportRecipientEmailAddress] CC:@"" subject:bugTitle body:emailBody];
            if (composeEmailURL != nil) {
                [[UIApplication sharedApplication] openURL:composeEmailURL];
            }
        }
    } else {
        // User canceled JIRA composition. We don't need to hold on to ourselves anymore.
        self.strongSelf = nil;
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
{
    return [alertView textFieldAtIndex:0].text.length > 0;
}

#pragma mark - Public Methods

- (void)composeBugReportWithLogs:(NSArray *)logs;
{
    NSAssert(self.bugReportRecipientEmailAddress.length > 0, @"Canot compose a bug report without a recipient email address!");
    
    /*
     iOS 8 often fails to transfer the keyboard from a focused text field to a UIAlertView's text field.
     Transfer first responder to an invisble view when a debug screenshot is captured to make bug filing itself bug-free.
     */
    [self _stealFirstResponder];
    
    self.logs = logs;
    [self _showBugTitleCaptureAlert];
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
    self.strongSelf = self;
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
    self.strongSelf = nil;
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
