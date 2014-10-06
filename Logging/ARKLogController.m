//
//  ARKLogController.m
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogController.h"
#import "ARKLogController_Testing.h"

#import "ARKAardvarkLog.h"
#import "ARKEmailBugReporter.h"


NSString *const ARKLogsFileName = @"ARKLogs";
NSString *const ARKScreenshotFlashAnimationKey = @"ScreenshotFlashAnimation";


@interface ARKInvisibleView : UIView
@end


@interface ARKLogController ()

@property (nonatomic, strong, readwrite) NSMutableArray *logs;
@property (nonatomic, strong, readonly) NSOperationQueue *loggingQueue;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier persistLogsBackgroundTaskIdentifier;

@property (nonatomic, strong, readwrite) UILongPressGestureRecognizer *screenshotGestureRecognizer;
@property (nonatomic, strong, readwrite) UIView *whiteScreen;

@end


@implementation ARKLogController

#pragma mark - Class Methods

+ (instancetype)sharedInstance;
{
    static ARKLogController *ARKDefaultLogController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARKDefaultLogController = [[self class] new];
    });
    
    return ARKDefaultLogController;
}

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
    
    _maximumLogCount = 2000;
    _maximumLogCountToPersist = 500;
    
    NSArray *persistedLogs = [self _persistedLogs];
    if (persistedLogs.count > 0) {
        _logs = [persistedLogs mutableCopy];
    } else {
        _logs = [[NSMutableArray alloc] initWithCapacity:(2 * _maximumLogCount)];
    }
    
    _loggingQueue = [NSOperationQueue new];
    _loggingQueue.maxConcurrentOperationCount = 1;
    
    if ([_loggingQueue respondsToSelector:@selector(setQualityOfService:)]) {
        // iOS 8 API
        _loggingQueue.qualityOfService = NSQualityOfServiceBackground;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController;
{
    return [ARKAardvarkLog formattedLogs:self.allLogs];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType;
{
    return [ARKAardvarkLog formattedLogs:self.allLogs];
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
{
    /*
     iOS 8 often fails to transfer the keyboard from a focused text field to a UIAlertView's text field.
     Transfer first responder to an invisble view when a debug screenshot is captured to make bug filing itself bug-free.
     */
    [self _stealFirstResponder];
    
    [self.whiteScreen removeFromSuperview];
    self.whiteScreen = nil;
    
    [self.bugReporter composeBugReportWithLogs:self.allLogs];
}

#pragma mark - Public Methods

- (void)installScreenshotGestureRecognizer;
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSAssert(self.bugReporter != nil, @"Bug reporter must not be nil when installing the screenshot gesture recognizer!");
        
        // First, uninstall an existing gesture recognizer.
        [self uninstallScreenshotGestureRecognizer];
        
        self.screenshotGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressDetected:)];
        self.screenshotGestureRecognizer.cancelsTouchesInView = NO;
        self.screenshotGestureRecognizer.numberOfTouchesRequired = 2;
        [[[UIApplication sharedApplication] keyWindow] addGestureRecognizer:self.screenshotGestureRecognizer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidBecomeKeyNotification:) name:UIWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResignKeyNotification:) name:UIWindowDidResignKeyNotification object:nil];
    }];
}

- (void)uninstallScreenshotGestureRecognizer;
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.screenshotGestureRecognizer.view removeGestureRecognizer:self.screenshotGestureRecognizer];
        self.screenshotGestureRecognizer = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidResignKeyNotification object:nil];
    }];
}

- (void)appendLog:(ARKAardvarkLog *)log;
{
    [self.loggingQueue addOperationWithBlock:^{
        // Don't proactively trim too often.
        if (self.logs.count >= 2 * self.maximumLogCount) {
            // We've held on to 2x more logs than we'll ever expose. Trim!
            [self _trimLogs_inLoggingQueue];
        }
        
        [self.logs addObject:log];
    }];
}

- (NSArray *)allLogs;
{
    __block NSArray *logs = nil;
    
    [self.loggingQueue addOperationWithBlock:^{
        [self _trimLogs_inLoggingQueue];
        
        logs = [self.logs copy];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
    
    return logs;
}

- (void)clearLocalLogs;
{
    [self.loggingQueue addOperationWithBlock:^{
        [self.logs removeAllObjects];
        [self _persistLogs_inLoggingQueue];
    }];
    
    [self.loggingQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

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

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
{
    self.persistLogsBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
    }];
    
    [self.loggingQueue addOperationWithBlock:^{
        [self _persistLogs_inLoggingQueue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.persistLogsBackgroundTaskIdentifier];
        });
    }];
}

- (NSString *)_pathToPersistedLogs;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = paths.firstObject;
    
    return [applicationSupportDirectory stringByAppendingPathComponent:ARKLogsFileName];
}

- (NSArray *)_persistedLogs;
{
    NSString *filePath = [self _pathToPersistedLogs];
    NSData *persistedLogData = [[NSFileManager defaultManager] contentsAtPath:filePath];
    NSArray *persistedLogs = persistedLogData ? [NSKeyedUnarchiver unarchiveObjectWithData:persistedLogData] : nil;
    if ([persistedLogs isKindOfClass:[NSArray class]] && persistedLogs.count > 0) {
        return persistedLogs;
    }
    
    return nil;
}

- (void)_persistLogs_inLoggingQueue;
{
    // Trim and perist logs when the app is backgrounded.
    [self _trimLogsForPersisting_inLoggingQueue];
    
    NSString *filePath = [self _pathToPersistedLogs];
    
    if (self.logs.count == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    } else {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSKeyedArchiver archivedDataWithRootObject:[self.logs copy]] attributes:nil];
    }
}

- (void)_trimLogs_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logs.count;
    if (numberOfLogs > self.maximumLogCount) {
        [self.logs removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCount)];
    }
}

- (void)_trimLogsForPersisting_inLoggingQueue;
{
    NSUInteger numberOfLogs = self.logs.count;
    if (numberOfLogs > self.maximumLogCountToPersist) {
        [self.logs removeObjectsInRange:NSMakeRange(0, numberOfLogs - self.maximumLogCountToPersist)];
    }
}

- (void)_stealFirstResponder;
{
    ARKInvisibleView *invisibleView = [ARKInvisibleView new];
    invisibleView.layer.opacity = 0.0;
    [self.screenshotGestureRecognizer.view addSubview:invisibleView];
    [invisibleView becomeFirstResponder];
    [invisibleView removeFromSuperview];
}

@end


@implementation ARKInvisibleView

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

@end
