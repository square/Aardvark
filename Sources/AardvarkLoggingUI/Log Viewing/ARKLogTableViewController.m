//
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

@import CoreAardvark;

#import "ARKLogTableViewController.h"
#import "ARKLogTableViewController_Testing.h"

#import "ARKIndividualLogViewController.h"
#import "ARKScreenshotViewController.h"
#import "UIActivityViewController+ARKAdditions.h"


@interface ARKLogTableViewController () <UIActionSheetDelegate, UIPopoverControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, copy) NSArray *logMessages;
@property (nonatomic, copy) NSArray *filteredLogs;
@property (nonatomic, copy) NSString *searchStringForFilteredLogs;
@property (nonatomic) BOOL viewWillAppearForFirstTimeCalled;
@property (nonatomic) BOOL hasScrolledToBottom;

@property (nonatomic) UIActionSheet *clearLogsConfirmationActionSheet;
@property (nonatomic, weak) UIBarButtonItem *shareBarButtonItem;

@property (nonatomic, strong) UIPopoverController *activitySheetPopoverController;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSString *searchString;

#if TARGET_IPHONE_SIMULATOR
@property (nonatomic) UIActionSheet *printLogsActionSheet;
@property (nonatomic) NSInteger printLogsToConsoleButtonIndex;
@property (nonatomic) NSInteger saveLogsToFileButtonIndex;
#endif

@end


@implementation ARKLogTableViewController

#pragma mark - Initialization

- (instancetype)initWithLogStore:(ARKLogStore *)logStore logFormatter:(id <ARKLogFormatter>)logFormatter;
{
    ARKCheckCondition(logStore, nil, @"Must pass a log store.");
    ARKCheckCondition(logFormatter, nil, @"Must pass a logFormatter.");

    self = [super initWithNibName:nil bundle:nil];
    
    _logStore = logStore;
    _logFormatter = logFormatter;
    _minutesBetweenTimestamps = 3;
    
    return self;
}

- (instancetype)init;
{
    return [self initWithLogStore:[ARKLogDistributor defaultDistributor].defaultLogStore logFormatter:[ARKDefaultLogFormatter new]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
    return [self init];
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)viewDidLayoutSubviews;
{
    [super viewDidLayoutSubviews];
    
    if (!self.hasScrolledToBottom && self.filteredLogs.count > 0) {
        [self _scrollTableViewToBottomAnimated:NO];
        self.hasScrolledToBottom = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated;
{
    [self _reloadLogs];
    
    if (!self.viewWillAppearForFirstTimeCalled) {
        [self _viewWillAppearForFirstTime:animated];
        self.viewWillAppearForFirstTimeCalled = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad;
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 34.0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.delegate = self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }

    if (self.title.length == 0) {
        self.title = NSLocalizedString(@"Logs", @"Title of log viewing screen.");
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
#if TARGET_IPHONE_SIMULATOR
    if (actionSheet == self.printLogsActionSheet) {
        NSMutableString *logsText = [NSMutableString string];
        for (ARKLogMessage *logMessage in self.filteredLogs) {
            [logsText appendFormat:@"%@\n", [self.logFormatter formattedLogMessage:logMessage]];
        }
        
        if (logsText.length > 0) {
            if (buttonIndex == self.printLogsToConsoleButtonIndex) {
                NSLog(@"Logs:\n%@", logsText);
                
            } else if (buttonIndex == self.saveLogsToFileButtonIndex) {
                NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Logs.txt"];
                [logsText writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
                NSLog(@"Logs saved to %@", filePath);
            }
        }
        
        return;
    }
#endif
    
    if (actionSheet == self.clearLogsConfirmationActionSheet) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self.logStore clearLogsWithCompletionHandler:NULL];
            [self _reloadLogs];
        }
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;
{
    self.activitySheetPopoverController = nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController;
{
    if (searchController.isActive) {
        self.searchString = searchController.searchBar.text;
        searchController.searchBar.placeholder = (self.searchString.length > 0) ? self.searchString : NSLocalizedString(@"Search", @"The default placeholder text for the search bar");
        [self _reloadFilteredLogs];
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController;
{
    searchController.searchBar.text = self.searchString;
    [self updateSearchResultsForSearchController:searchController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex;
{
    ARKCheckCondition(sectionIndex == 0, 0, @"There is only one section index!");
    return self.filteredLogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *const ARKLogCellIdentifier = @"ARKLogCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ARKLogCellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ARKLogCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSInteger index = [indexPath row];
    ARKLogMessage *currentLog = self.filteredLogs[index];
    
    // Find the most recent separator log, or the first log in the list.
    ARKLogMessage *logForTimestampDelta = nil;
    for (NSInteger i = index; i >= 0; i--) {
        logForTimestampDelta = self.filteredLogs[i];
        if (logForTimestampDelta.type == ARKLogTypeSeparator) {
            break;
        }
    }
    
    NSTimeInterval delta = logForTimestampDelta ? [currentLog.date timeIntervalSinceDate:logForTimestampDelta.date] : 0.0;
    cell.textLabel.text = [NSString stringWithFormat:@"+%.1f\t%@", delta, currentLog.text];
    
    UIColor *textColor = nil;
    UIColor *backgroundColor = nil;
    switch (currentLog.type) {
        case ARKLogTypeSeparator:
        {
            NSCalendarUnit dayComponents = (NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
            NSDateComponents *logDateComponents = [[NSCalendar currentCalendar] components:dayComponents fromDate:currentLog.date];
            NSDateComponents *todayDateComponents = [[NSCalendar currentCalendar] components:dayComponents fromDate:[NSDate date]];
            
            BOOL const logWasCreatedToday = [logDateComponents isEqual:todayDateComponents];
            if ([currentLog isKindOfClass:[ARKTimestampLogMessage class]]) {
                if (logWasCreatedToday) {
                    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:currentLog.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
                } else {
                    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:currentLog.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
                }
                
            } else {
                if (logWasCreatedToday) {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                           currentLog.text,
                                           [NSDateFormatter localizedStringFromDate:currentLog.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]];
                } else {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                           currentLog.text,
                                           [NSDateFormatter localizedStringFromDate:currentLog.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
                }
            }
            
            textColor = [UIColor whiteColor];
            backgroundColor = [UIColor blueColor];
            break;
        }
        case ARKLogTypeError:
            textColor = [UIColor whiteColor];
            backgroundColor = [UIColor redColor];
            break;
        case ARKLogTypeDefault:
            // Set the text color to `nil`, which causes it to be reset to the default label text color.
            textColor = nil;
            backgroundColor = [UIColor clearColor];
            break;
        case ARKLogTypeScreenshot:
            textColor = [UIColor whiteColor];
            backgroundColor = [UIColor purpleColor];
            break;
    }
    
    cell.textLabel.textColor = textColor;
    cell.backgroundColor = backgroundColor;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    ARKLogMessage *logMessage = self.filteredLogs[[indexPath row]];
    if (logMessage.image != nil) {
        ARKScreenshotViewController *screenshotViewer = [[ARKScreenshotViewController alloc] initWithLogMessage:logMessage];
        
        [self.navigationController pushViewController:screenshotViewer animated:YES];
    } else {
        ARKIndividualLogViewController *individualLogViewer = [[ARKIndividualLogViewController alloc] initWithLogMessage:logMessage];
        
        [self.navigationController pushViewController:individualLogViewer animated:YES];
    }
}

#pragma mark - Properties

- (void)setMinutesBetweenTimestamps:(NSUInteger)minutesBetweenTimestamps;
{
    if (_minutesBetweenTimestamps == minutesBetweenTimestamps) {
        return;
    }
    
    _minutesBetweenTimestamps = minutesBetweenTimestamps;
    [self _reloadLogs];
}

#pragma mark - Public Methods

- (NSArray *)contentForActivitySheet;
{
    NSMutableArray *formattedLogMessages = [NSMutableArray new];
    NSMutableArray *contentForActivitySheet = [NSMutableArray new];
    for (ARKLogMessage *logMessage in self.filteredLogs) {
        [formattedLogMessages addObject:[self.logFormatter formattedLogMessage:logMessage]];
        
        UIImage *const logImage = logMessage.image;
        if (logImage != nil) {
            [contentForActivitySheet addObject:logImage];
        }
    }
    
    if (formattedLogMessages.count > 0) {
        [contentForActivitySheet addObject:[formattedLogMessages componentsJoinedByString:@"\n"]];
    }
    
    return contentForActivitySheet;
}

#pragma mark - Private Methods

- (IBAction)_openActivitySheet:(id)sender;
{
#if TARGET_IPHONE_SIMULATOR
    // On the simulator, show an action sheet letting the developer write all logs to the console, or to a file on the desktop.
    self.printLogsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Action sheet button title to cancel Print/Save Logs action sheet.")
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
    
    self.printLogsToConsoleButtonIndex = [self.printLogsActionSheet addButtonWithTitle:NSLocalizedString(@"Print Logs to Console", @"Action sheet button to write logs to the console.")];
    self.saveLogsToFileButtonIndex = [self.printLogsActionSheet addButtonWithTitle:NSLocalizedString(@"Save Logs to File", @"Action sheet button to save logs to a file (and NSLog the path to that file).")];
    
    [self.printLogsActionSheet showInView:self.view];
    
#else
    // Show a share sheet so the user can email logs.
    NSArray *formattedLogMessages = [self contentForActivitySheet];
    UIActivityViewController *activityViewController = [UIActivityViewController ARK_newAardvarkActivityViewControllerWithItems:formattedLogMessages];

    // UIActivityViewController must be presented modally on iPhone, but in a popover on iPad, according to Apple's docs.
    BOOL const isPhone = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    if (isPhone) {
        [self presentViewController:activityViewController animated:YES completion:NULL];
    } else {
        // isPad
        ARKCheckCondition(self.shareBarButtonItem, , @"Missing a share bar button item when that bar button item was clicked.");

        self.activitySheetPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.activitySheetPopoverController.delegate = self;
        [self.activitySheetPopoverController presentPopoverFromBarButtonItem:self.shareBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
#endif
}

- (IBAction)_clearLogs:(id)sender;
{
    self.clearLogsConfirmationActionSheet = [UIActionSheet new];
    self.clearLogsConfirmationActionSheet.destructiveButtonIndex = [self.clearLogsConfirmationActionSheet addButtonWithTitle:NSLocalizedString(@"Delete All Logs", @"Action sheet button to clear all logs.")];
    self.clearLogsConfirmationActionSheet.cancelButtonIndex = [self.clearLogsConfirmationActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet button title to cancel clearing logs.")];
    
    self.clearLogsConfirmationActionSheet.delegate = self;
    [self.clearLogsConfirmationActionSheet showInView:self.view];
}

- (void)_applicationDidBecomeActive:(NSNotification *)notification;
{
    [self _reloadLogs];
}

- (void)_reloadLogs;
{
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        self.logMessages = [self _logMessagesWithMinuteSeparators:logMessages];
        [self _reloadFilteredLogs];
        
        [self.tableView reloadData];
    }];
}

- (void)_reloadFilteredLogs;
{
    BOOL isSubsetOfPreviousFilter = self.searchStringForFilteredLogs != nil && [self.searchString containsString:self.searchStringForFilteredLogs];
    self.searchStringForFilteredLogs = self.searchString;

    if (self.searchString.length > 0 && isSubsetOfPreviousFilter) {
        self.filteredLogs = [self.filteredLogs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"text CONTAINS[c] %@", self.searchString]];
    } else if (self.searchString.length > 0) {
        self.filteredLogs = [self.logMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"text CONTAINS[c] %@", self.searchString]];
    } else {
        self.filteredLogs = self.logMessages;
    }
}

- (NSArray *)_logMessagesWithMinuteSeparators:(NSArray *)logMessages;
{
    NSMutableArray *logMessagesWithMinuteSeparators = [NSMutableArray new];
    
    NSDate *previousTimestampDate = nil;
    for (ARKLogMessage *const logMessage in logMessages) {
        NSTimeInterval const secondsPerMinute = 60.0;
        if (!previousTimestampDate || [logMessage.date timeIntervalSinceDate:previousTimestampDate] > self.minutesBetweenTimestamps * secondsPerMinute) {
            NSTimeInterval const timeIntervalRoundedToMinute = [logMessage.date timeIntervalSinceReferenceDate] - fmod([logMessage.date timeIntervalSinceReferenceDate], secondsPerMinute);
            NSDate *const timestampDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeIntervalRoundedToMinute];
            
            ARKTimestampLogMessage *const timestampLogMessage = [[ARKTimestampLogMessage alloc] initWithDate:timestampDate];
            if (timestampLogMessage != nil) {
                [logMessagesWithMinuteSeparators addObject:timestampLogMessage];
                previousTimestampDate = timestampDate;
            }
        }
        
        [logMessagesWithMinuteSeparators addObject:logMessage];
    }
    
    return logMessagesWithMinuteSeparators;
}

- (void)_viewWillAppearForFirstTime:(BOOL)animated;
{
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_openActivitySheet:)];
    self.shareBarButtonItem = shareButton;

    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(_clearLogs:)];
    
    self.navigationItem.rightBarButtonItems = @[shareButton, deleteButton];
}

- (void)_scrollTableViewToBottomAnimated:(BOOL)animated;
{
    CGPoint bottomOffset = CGPointMake(0.0f, self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.contentInset.bottom);
    if (bottomOffset.y > 0.0f) {
        [self.tableView setContentOffset:bottomOffset animated:NO];
    }
}

@end


#pragma mark - ARKTimestampLogMessage

@implementation ARKTimestampLogMessage

#pragma mark - Class Methods

+ (NSDateFormatter *)sharedDateFormatter;
{
    static NSDateFormatter *sharedDateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDateFormatter = [NSDateFormatter new];
        sharedDateFormatter.dateStyle = NSDateFormatterNoStyle;
        sharedDateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    
    return sharedDateFormatter;
}

#pragma mark - Initialization

- (instancetype)initWithDate:(NSDate *)date;
{
    NSString *text = [[[self class] sharedDateFormatter] stringFromDate:date];
    return [super initWithText:text image:nil type:ARKLogTypeSeparator userInfo:nil date:date];
}

@end
