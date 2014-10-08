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
#import "ARKLogController.h"
#import "ARKLogFormatter.h"


NSString *const ARKScreenshotFlashAnimationKey = @"ScreenshotFlashAnimation";


@interface ARKInvisibleView : UIView
@end


@interface ARKEmailBugReporter () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) UILongPressGestureRecognizer *screenshotGestureRecognizer;
@property (nonatomic, strong, readwrite) UIView *whiteScreen;

@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic, strong) UIWindow *emailComposeWindow;

@property (nonatomic, strong) NSArray *logs;

@end


@implementation ARKEmailBugReporter

#pragma mark - Class Methods

+ (instancetype)allocWithZone:(struct _NSZone *)zone;
{
    if ([Aardvark isAardvarkLoggingEnabled]) {
        return [super allocWithZone:zone];
    } else {
        return nil;
    }
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
    _emailComposeWindowLevel = UIWindowLevelStatusBar + 3.0;
    
    return self;
}

- (void)dealloc;
{
    [self disableBugReporting];
}

#pragma mark - ARKBugReporter

- (void)enableBugReporting;
{
    NSAssert([NSThread isMainThread], @"Attempting to enable bug reporting off of the main therad (%@)", [NSThread currentThread]);
    
    // First, uninstall an existing gesture recognizer.
    [self disableBugReporting];
    
    self.screenshotGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressDetected:)];
    self.screenshotGestureRecognizer.cancelsTouchesInView = NO;
    self.screenshotGestureRecognizer.numberOfTouchesRequired = 2;
    [[[UIApplication sharedApplication] keyWindow] addGestureRecognizer:self.screenshotGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidBecomeKeyNotification:) name:UIWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResignKeyNotification:) name:UIWindowDidResignKeyNotification object:nil];
}

- (void)disableBugReporting;
{
    NSAssert([NSThread isMainThread], @"Attempting to enable bug reporting off of the main therad (%@)", [NSThread currentThread]);
    
    [self.screenshotGestureRecognizer.view removeGestureRecognizer:self.screenshotGestureRecognizer];
    self.screenshotGestureRecognizer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidResignKeyNotification object:nil];
}

- (void)composeBugReportWithLogs:(NSArray *)logs;
{
    NSAssert(self.bugReportRecipientEmailAddress.length > 0, @"Attempting to compose a bug report without a recipient email address");
    
    /*
     iOS 8 often fails to transfer the keyboard from a focused text field to a UIAlertView's text field.
     Transfer first responder to an invisble view when a debug screenshot is captured to make bug filing itself bug-free.
     */
    [self _stealFirstResponder];
    
    self.logs = logs;
    [self _showBugTitleCaptureAlert];
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
{
    [self.whiteScreen removeFromSuperview];
    self.whiteScreen = nil;
    
    [self composeBugReportWithLogs:[ARKLogController sharedInstance].allLogs];
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
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
{
    return [alertView textFieldAtIndex:0].text.length > 0;
}

#pragma mark - Properties

- (void)_longPressDetected:(UILongPressGestureRecognizer *)longPressRecognizer;
{
    if (longPressRecognizer == self.screenshotGestureRecognizer && longPressRecognizer.state == UIGestureRecognizerStateBegan && self.whiteScreen == nil) {
        // Take a screenshot.
        ARKLogScreenshot();
        
        // Flash the screen to simulate a screenshot being taken.
        self.whiteScreen = [[UIView alloc] initWithFrame:self.screenshotGestureRecognizer.view.frame];
        self.whiteScreen.layer.opacity = 0.0f;
        self.whiteScreen.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        [self.screenshotGestureRecognizer.view addSubview:self.whiteScreen];
        
        CAKeyframeAnimation *screenFlash = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        screenFlash.duration = 0.8;
        screenFlash.values = @[@0.0, @0.8, @1.0, @0.9, @0.8, @0.7, @0.6, @0.5, @0.4, @0.3, @0.2, @0.1, @0.0];
        screenFlash.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        screenFlash.delegate = self;
        
        // Start the screen flash animation. Once this is done we'll fire up the bug reporter.
        [self.whiteScreen.layer addAnimation:screenFlash forKey:ARKScreenshotFlashAnimationKey];
    }
}

- (void)_windowDidBecomeKeyNotification:(NSNotification *)notification;
{
    UIWindow *window = [[notification object] isKindOfClass:[UIWindow class]] ? (UIWindow *)[notification object] : nil;
    [window addGestureRecognizer:self.screenshotGestureRecognizer];
}

- (void)_windowDidResignKeyNotification:(NSNotification *)notification;
{
    UIWindow *window = [[notification object] isKindOfClass:[UIWindow class]] ? (UIWindow *)[notification object] : nil;
    [window removeGestureRecognizer:self.screenshotGestureRecognizer];
}

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
    self.logs = nil;
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
