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

@import MessageUI;

#import "ARKEmailBugReporter.h"
#import "ARKEmailBugReporter_Testing.h"

#import "AardvarkDefines.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKEmailAttachment.h"
#import "ARKEmailBugReportConfiguration.h"
#import "ARKScreenshotLogging.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"


NSString *const ARKScreenshotFlashAnimationKey = @"ScreenshotFlashAnimation";


@interface ARKInvisibleView : UIView
@end


@interface CALayer (HierarchyDescription)

- (void)_ARK_appendRecursiveLayerHierarchyDescriptionToString:(NSMutableString *)mutableDescription withIndentationLevel:(NSUInteger)indentationLevel;

@end


@implementation CALayer (HierarchyDescription)

- (void)_ARK_appendRecursiveLayerHierarchyDescriptionToString:(NSMutableString *)mutableDescription withIndentationLevel:(NSUInteger)indentationLevel;
{
    for (int i = 0 ; i < indentationLevel ; i++) {
        [mutableDescription appendString:@"   | "];
    }
    
    [mutableDescription appendFormat:@"%@\n", self];
    
    for (CALayer *sublayer in self.sublayers) {
        [sublayer _ARK_appendRecursiveLayerHierarchyDescriptionToString:mutableDescription withIndentationLevel:(indentationLevel + 1)];
    }
}

@end


@interface UIView (HierarchyDescription)

/// Appends the recursive description of the view hierarchy starting with the current view to the provided mutable string. Description is similar to the private `-[UIView recursiveDescription]` method.
- (void)_ARK_appendRecursiveViewHierarchyDescriptionToString:(NSMutableString *)mutableDescription withIndentationLevel:(NSUInteger)indentationLevel usingViewControllerMap:(NSMapTable<UIView *, UIViewController *> *)viewControllerMap;

@end


@implementation UIView (HierarchyDescription)

- (void)_ARK_appendRecursiveViewHierarchyDescriptionToString:(NSMutableString *)mutableDescription withIndentationLevel:(NSUInteger)indentationLevel usingViewControllerMap:(NSMapTable<UIView *, UIViewController *> *)viewControllerMap;
{
    UIViewController *const viewController = [viewControllerMap objectForKey:self];
    if (viewController != nil) {
        for (int i = 0 ; i < indentationLevel ; i++) {
            [mutableDescription appendString:@"   | "];
        }
        
        [mutableDescription appendFormat:@"VC: %@\n", viewController];
    }
    
    for (int i = 0 ; i < indentationLevel ; i++) {
        [mutableDescription appendString:@"   | "];
    }
    
    [mutableDescription appendFormat:@"%@\n", self];
    
    // Each subview's layer is also a sublayer, but we should only include it in the hierarchy once (with the subview).
    NSMutableSet<CALayer *> *const sublayersToSkip = [NSMutableSet<CALayer *> setWithCapacity:self.subviews.count];
    
    for (UIView *subview in self.subviews) {
        [subview _ARK_appendRecursiveViewHierarchyDescriptionToString:mutableDescription withIndentationLevel:(indentationLevel + 1) usingViewControllerMap:viewControllerMap];
        [sublayersToSkip addObject:subview.layer];
    }
    
    for (CALayer *sublayer in self.layer.sublayers) {
        if ([sublayersToSkip containsObject:sublayer]) {
            continue;
        }
        
        [sublayer _ARK_appendRecursiveLayerHierarchyDescriptionToString:mutableDescription withIndentationLevel:(indentationLevel + 1)];
    }
}

@end


@interface UIViewController (HierarchyDescription)

- (void)_ARK_appendRecursiveViewControllerMappingToMapTable:(NSMapTable<UIView *, UIViewController *> *)mapTable;

@end


@implementation UIViewController (HierarchyDescription)

- (void)_ARK_appendRecursiveViewControllerMappingToMapTable:(NSMapTable<UIView *, UIViewController *> *)mapTable;
{
    if (self.isViewLoaded) {
        [mapTable setObject:self forKey:self.view];
    }
    
    for (UIViewController *childViewController in self.childViewControllers) {
        [childViewController _ARK_appendRecursiveViewControllerMappingToMapTable:mapTable];
    }
}

@end


@interface ARKDefaultPromptPresenter : NSObject <ARKEmailBugReporterPromptingDelegate>

@property (nonatomic) ARKEmailBugReportConfiguration *configuration;

@property (nonatomic) ARKEmailBugReporterCustomPromptCompletionBlock completion;

@end


@interface ARKEmailBugReporter () <CAAnimationDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) UIView *screenFlashView;

@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) UIWindow *emailComposeWindow;
@property (nonatomic, weak) UIWindow *previousKeyWindow;

@property (nonatomic, copy, readonly) NSMutableArray *mutableLogStores;

@property (nonatomic) BOOL attachScreenshotToNextBugReport;

@property (nonatomic) NSString *viewHierarchyDescription;

@end


@implementation ARKEmailBugReporter

#pragma mark - Initialization

- (instancetype)initWithEmailAddress:(NSString *)emailAddress logStore:(ARKLogStore *)logStore;
{
    self = [super init];
    
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
    _attachesViewHierarchyDescriptionWithScreenshot = YES;
    
    _mutableLogStores = [NSMutableArray new];
    
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
    ARKCheckCondition(self.bugReportRecipientEmailAddress.length > 0, , @"Attempting to compose a bug report without a recipient email address.");
    ARKCheckCondition(self.mutableLogStores.count > 0, , @"Attempting to compose a bug report without logs.");
    
    self.attachScreenshotToNextBugReport = attachScreenshot;
    
    if (attachScreenshot && !self.screenFlashView) {
        // Take a screenshot.
        ARKLogScreenshot();
        
        if (self.attachesViewHierarchyDescriptionWithScreenshot) {
            NSMutableString *mutableViewHierarchyDescription = [NSMutableString new];
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                NSMapTable<UIView *, UIViewController *> *const viewControllerMap = [NSMapTable<UIView *, UIViewController *> strongToStrongObjectsMapTable];
                [window.rootViewController _ARK_appendRecursiveViewControllerMappingToMapTable:viewControllerMap];
                
                [window _ARK_appendRecursiveViewHierarchyDescriptionToString:mutableViewHierarchyDescription withIndentationLevel:0 usingViewControllerMap:viewControllerMap];
            }
            self.viewHierarchyDescription = mutableViewHierarchyDescription;
        }
        
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
        [self _showBugReportPrompt];
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
    
    [self _showBugReportPrompt];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _dismissEmailComposeWindow];
    }];
}

#pragma mark - Properties

- (UIWindow *)emailComposeWindow;
{
    if (!_emailComposeWindow) {
        _emailComposeWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _emailComposeWindow.windowLevel = self.emailComposeWindowLevel;
    }
    
    return _emailComposeWindow;
}

#pragma mark - Public Methods

- (NSData *)formattedLogMessagesAsData:(NSArray *)logMessages;
{
    NSMutableArray *const formattedLogMessages = [NSMutableArray new];
    for (ARKLogMessage *const logMessage in logMessages) {
        [formattedLogMessages addObject:[self.logFormatter formattedLogMessage:logMessage]];
    }
    
    NSData *const formattedLogMessagesAsData = [[formattedLogMessages componentsJoinedByString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
    if (formattedLogMessagesAsData != nil) {
        return formattedLogMessagesAsData;
    } else {
        return [NSData new];
    }
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

- (void)_showBugReportPrompt;
{
    id <ARKEmailBugReporterPromptingDelegate> const promptPresenter = (self.promptingDelegate ?: [ARKDefaultPromptPresenter new]);
    [promptPresenter showBugReportingPromptForConfiguration:[self _configurationWithCurrentSettings] completion:^(ARKEmailBugReportConfiguration * _Nullable configuration) {
        if (configuration != nil) {
            [self _createBugReportWithConfiguration:configuration];
        }
    }];
}

- (ARKEmailBugReportConfiguration *)_configurationWithCurrentSettings;
{
    ARKEmailBugReportConfiguration *const configuration = [[ARKEmailBugReportConfiguration alloc] init];
    
    if (self.emailAttachmentAdditionsDelegate != nil) {
        NSMutableArray *const filteredLogStores = [NSMutableArray arrayWithCapacity:self.logStores.count];
        for (ARKLogStore *logStore in self.logStores) {
            if ([self.emailAttachmentAdditionsDelegate emailBugReporter:self shouldIncludeLogStoreInBugReport:logStore]) {
                [filteredLogStores addObject:logStore];
            }
        }
        configuration.logStores = filteredLogStores;
        
        configuration.additionalAttachments = [self.emailAttachmentAdditionsDelegate additionalEmailAttachmentsForEmailBugReporter:self];
        
    } else {
        configuration.logStores = [self.logStores copy];
    }
    
    configuration.includesScreenshot = self.attachScreenshotToNextBugReport;
    configuration.includesViewHierarchyDescription = (self.attachScreenshotToNextBugReport && self.attachesViewHierarchyDescriptionWithScreenshot);
    
    return configuration;
}

- (void)_createBugReportWithConfiguration:(ARKEmailBugReportConfiguration *)configuration;
{
    NSMapTable *logStoresToLogMessagesMap = [NSMapTable new];
    NSDictionary *emailBodyAdditions = [self.emailBodyAdditionsDelegate emailBodyAdditionsForEmailBugReporter:self];
    
    if ([MFMailComposeViewController canSendMail]) {
        self.mailComposeViewController = [MFMailComposeViewController new];
        
        [self.mailComposeViewController setToRecipients:@[self.bugReportRecipientEmailAddress]];
        [self.mailComposeViewController setSubject:configuration.prefilledEmailSubject];
        
        dispatch_group_t logStoreRetrievalDispatchGroup = dispatch_group_create();
        dispatch_group_enter(logStoreRetrievalDispatchGroup);
        
        NSArray<ARKLogStore *> *const logStores = configuration.logStores;
        for (ARKLogStore *logStore in logStores) {
            dispatch_group_enter(logStoreRetrievalDispatchGroup);
            [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
                [logStoresToLogMessagesMap setObject:logMessages forKey:logStore];
                dispatch_group_leave(logStoreRetrievalDispatchGroup);
            }];
        }
        
        // Once all log messages have been retrieved, attach the data and show the compose window.
        dispatch_group_notify(logStoreRetrievalDispatchGroup, dispatch_get_main_queue(), ^{
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
                
                
                if (configuration.includesScreenshot && self.attachScreenshotToNextBugReport) {
                    NSData *const mostRecentImage = [self _mostRecentImageAsPNG:logMessages];
                    if (mostRecentImage.length > 0) {
                        [self.mailComposeViewController addAttachmentData:mostRecentImage mimeType:@"image/png" fileName:screenshotFileName];
                    }
                }
                
                NSData *formattedLogs = [self formattedLogMessagesAsData:logMessages];
                if (formattedLogs.length) {
                    [self.mailComposeViewController addAttachmentData:formattedLogs mimeType:[self formattedLogMessagesDataMIMEType] fileName:logsFileName];
                }
            }
            
            if (configuration.includesViewHierarchyDescription && self.viewHierarchyDescription != nil) {
                NSString *viewHierarchyFileName = [NSLocalizedString(@"view_hierarchy", @"File name for view hierarchy attachment") stringByAppendingPathExtension:@"txt"];
                NSData *const viewHierarchyData = [self.viewHierarchyDescription dataUsingEncoding:NSUTF8StringEncoding];
                if (viewHierarchyData.length > 0) {
                    [self.mailComposeViewController addAttachmentData:viewHierarchyData mimeType:@"text/plain" fileName:viewHierarchyFileName];
                }
            }
            self.viewHierarchyDescription = nil;
            
            for (ARKEmailAttachment *attachment in configuration.additionalAttachments) {
                [self.mailComposeViewController addAttachmentData:attachment.data mimeType:attachment.dataMIMEType fileName:attachment.fileName];
            }
            
            [self.mailComposeViewController setMessageBody:emailBody isHTML:NO];
            self.mailComposeViewController.mailComposeDelegate = self;
            [self _showEmailComposeWindow];
        });
        
        dispatch_group_leave(logStoreRetrievalDispatchGroup);
        
    } else {
        NSArray<ARKLogStore *> *const logStores = configuration.logStores;
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
                    
                    NSURL *const composeEmailURL = [self _emailURLWithRecipients:@[self.bugReportRecipientEmailAddress] CC:@"" subject:configuration.prefilledEmailSubject body:emailBody];
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
    
    if (recentErrorLogs.length > 0 ) {
        // Remove the final newline and create an immutable string.
        return [recentErrorLogs stringByReplacingCharactersInRange:NSMakeRange(recentErrorLogs.length - 1, 1) withString:@""];
    } else {
        return @"";
    }
}

- (NSData *)_mostRecentImageAsPNG:(NSArray *)logMessages;
{
    for (ARKLogMessage *logMessage in [logMessages reverseObjectEnumerator]) {
        UIImage *const logImage = logMessage.image;
        if (logImage != nil) {
            return UIImagePNGRepresentation(logImage);
        }
    }
    
    return nil;
}

- (NSURL *)_emailURLWithRecipients:(NSArray *)recipients CC:(NSString *)CCLine subject:(NSString *)subjectLine body:(NSString *)bodyText;
{
    NSString *const defaultPrefix = @"mailto:";
    NSArray *const prefixes = @[@"inbox-gmail://co", @"sparrow://", @"googlegmail:///co", defaultPrefix];
    
    NSURL *URL = nil;
    for (NSString *prefix in prefixes) {
        URL = [self _emailURLWithPrefix:prefix recipients:recipients CC:CCLine subject:subjectLine body:bodyText shouldCheckCanOpenURL:YES];
        
        if (URL != nil) {
            break;
        }
    }
    
    ARKCheckCondition(URL != nil, [self _emailURLWithPrefix:defaultPrefix recipients:recipients CC:CCLine subject:subjectLine body:bodyText shouldCheckCanOpenURL:NO], @"iOS prevented us from querying for URLs with %@. Defaulting to %@", prefixes, defaultPrefix);
    
    return URL;
}

- (NSURL *)_emailURLWithPrefix:(NSString *)prefix recipients:(NSArray *)recipients CC:(NSString *)CCLine subject:(NSString *)subjectLine body:(NSString *)bodyText shouldCheckCanOpenURL:(BOOL)shouldCheckCanOpenURL;
{
    NSString *const recipientsEscapedString = [[recipients componentsJoinedByString:@","] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *const toArgument = (recipients.count > 0) ? [NSString stringWithFormat:@"to=%@&", recipientsEscapedString] : @"";
    NSString *const URLString = [NSString stringWithFormat:@"%@?%@cc=%@&subject=%@&body=%@",
                                 prefix,
                                 toArgument,
                                 [CCLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                 [subjectLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                 [bodyText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *const URL = [NSURL URLWithString:URLString];
    if (shouldCheckCanOpenURL) {
        return [[UIApplication sharedApplication] canOpenURL:URL] ? URL : nil;
    } else {
        return URL;
    }
}


@end


@implementation ARKInvisibleView

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

@end


@implementation ARKDefaultPromptPresenter

- (void)showBugReportingPromptForConfiguration:(nonnull ARKEmailBugReportConfiguration *)configuration completion:(nonnull ARKEmailBugReporterCustomPromptCompletionBlock)completion {
    self.configuration = configuration;
    self.completion = completion;
    
    [self _showBugTitleCaptureAlert];
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
    
    UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:composeReportButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textfield = [alertController.textFields firstObject];
        [self _createBugReportWithTitle:textfield.text];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.completion(nil);
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        [self _configureAlertTextfield:textField];
    }];
    
    UIViewController *viewControllerToPresentAlertController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (viewControllerToPresentAlertController.presentedViewController != nil) {
        viewControllerToPresentAlertController = viewControllerToPresentAlertController.presentedViewController;
    }
    
    /*
     Disabling animations here to avoid potential crashes resulting from unexpected view state in UIKit
     */
    [viewControllerToPresentAlertController presentViewController:alertController animated:NO completion:NULL];
}

- (void)_stealFirstResponder;
{
    ARKInvisibleView *invisibleView = [ARKInvisibleView new];
    invisibleView.layer.opacity = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:invisibleView];
    [invisibleView becomeFirstResponder];
    [invisibleView removeFromSuperview];
}

- (void)_configureAlertTextfield:(UITextField *)textField
{
    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textField.autocorrectionType = UITextAutocorrectionTypeYes;
    textField.spellCheckingType = UITextSpellCheckingTypeYes;
    textField.returnKeyType = UIReturnKeyDone;
}

- (void)_createBugReportWithTitle:(NSString *)title;
{
    self.configuration.prefilledEmailSubject = title;
    self.completion(self.configuration);
}

@end
