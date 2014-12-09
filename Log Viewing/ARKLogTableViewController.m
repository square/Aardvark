//
//  ARKLogTableViewController.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKLogTableViewController.h"

#import "ARKIndividualLogViewController.h"
#import "ARKDefaultLogFormatter.h"
#import "ARKLogDistributor.h"
#import "ARKLogMessage.h"
#import "ARKLogStore.h"
#import "ARKScreenshotViewController.h"
#import "UIActivityViewController+ARKAdditions.h"


@interface ARKTimestampLogMessage : ARKLogMessage

- (instancetype)initTimestampMessageWithDate:(NSDate *)date;

@end


@interface ARKLogTableViewController () <UIActionSheetDelegate>

@property (nonatomic, copy, readwrite) NSArray *logMessages;
@property (nonatomic, assign, readwrite) BOOL viewWillAppearForFirstTimeCalled;
@property (nonatomic, assign, readwrite) BOOL hasScrolledToBottom;

@end


@implementation ARKLogTableViewController

#pragma mark - Class Methods

+ (NSCalendar *)sharedCalendar;
{
    static NSCalendar *sharedCalendar = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedCalendar = [NSCalendar currentCalendar];
    });
    
    return sharedCalendar;
}

#pragma mark - Initialization

- (instancetype)initWithLogStore:(ARKLogStore *)logStore logFormatter:(id <ARKLogFormatter>)logFormatter;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logStore = logStore;
    _logFormatter = logFormatter;
    _minutesBetweenTimestamps = 3;
    
    return self;
}

- (instancetype)init;
{
    return [self initWithLogStore:[ARKLogDistributor defaultDistributor].defaultLogStore logFormatter:[ARKDefaultLogFormatter new]];
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)viewDidLayoutSubviews;
{
    [super viewDidLayoutSubviews];
    
    if (!self.hasScrolledToBottom && self.logMessages.count > 0) {
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
    
    self.title = @"Logs";
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self.logStore clearLogs];
        [self _reloadLogs];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex;
{
    ARKCheckCondition(sectionIndex == 0, 0, @"There is only one section index!");
    return self.logMessages.count;
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
    ARKLogMessage *currentLog = self.logMessages[index];
    
    ARKLogMessage *mostRecentSeparatorLog = nil;
    for (NSInteger i = index; i >= 0; i--) {
        mostRecentSeparatorLog = self.logMessages[i];
        if (mostRecentSeparatorLog.type == ARKLogTypeSeparator) {
            break;
        }
    }
    
    NSTimeInterval delta = mostRecentSeparatorLog ? [currentLog.creationDate timeIntervalSinceDate:mostRecentSeparatorLog.creationDate] : 0.0;
    cell.textLabel.text = [NSString stringWithFormat:@"+%.1f\t%@", delta, currentLog.text];
    
    UIColor *textColor = nil;
    UIColor *backgroundColor = nil;
    switch (currentLog.type) {
        case ARKLogTypeSeparator:
        {
            NSCalendarUnit dayComponents = (NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
            NSDateComponents *logDateComponents = [[[self class] sharedCalendar] components:dayComponents fromDate:currentLog.creationDate];
            NSDateComponents *todayDateComponents = [[[self class] sharedCalendar] components:dayComponents fromDate:[NSDate date]];
            
            BOOL logWasCreatedToday = [logDateComponents isEqual:todayDateComponents];
            if ([currentLog isKindOfClass:[ARKTimestampLogMessage class]]) {
                if (logWasCreatedToday) {
                    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
                } else {
                    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
                }
                
            } else {
                if (logWasCreatedToday) {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                           currentLog.text,
                                           [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]];
                } else {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                           currentLog.text,
                                           [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
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
            textColor = [UIColor blackColor];
            backgroundColor = [UIColor clearColor];
            break;
        default:
            break;
    }
    
    if ([cell respondsToSelector:@selector(separatorInset) /* iOS 7 or later */]) {
        cell.textLabel.textColor = textColor;
        cell.backgroundColor = backgroundColor;
    } else {
        // cell.backgroundColor doesn't work on iOS 6. Instead, set the text color.
        cell.textLabel.textColor = [textColor isEqual:[UIColor blackColor]] ? textColor : backgroundColor;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    ARKLogMessage *logMessage = self.logMessages[[indexPath row]];
    if (logMessage.image != nil) {
        ARKScreenshotViewController *screenshotViewer = [[ARKScreenshotViewController alloc] initWithLogMessage:logMessage];
        
        [self.navigationController pushViewController:screenshotViewer animated:YES];
    } else {
        ARKIndividualLogViewController *individualLogViewer = [[ARKIndividualLogViewController alloc] initWithLogMessage:logMessage];
        
        [self.navigationController pushViewController:individualLogViewer animated:YES];
    }
}

#pragma mark - Public Methods

- (NSArray *)contentForActivitySheet;
{
    NSMutableArray *formattedLogMessages = [NSMutableArray new];
    
    for (ARKLogMessage *logMessage in self.logMessages) {
        [formattedLogMessages addObject:[self.logFormatter formattedLogMessage:logMessage]];
        
        if (logMessage.image != nil) {
            [formattedLogMessages addObject:logMessage.image];
        }
    }
    
    return [formattedLogMessages copy];
}

#pragma mark - Private Methods

- (IBAction)_openActivitySheet:(id)sender;
{
    NSArray *formattedLogMessages = [self contentForActivitySheet];
    UIActivityViewController *activityViewController = [UIActivityViewController ARK_newAardvarkActivityViewControllerWithItems:formattedLogMessages];
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

- (IBAction)_clearLogs:(id)sender;
{
    UIActionSheet *confirmationSheet = [UIActionSheet new];
    confirmationSheet.destructiveButtonIndex = [confirmationSheet addButtonWithTitle:@"Delete All Logs"];
    confirmationSheet.cancelButtonIndex = [confirmationSheet addButtonWithTitle:@"Cancel"];
    
    confirmationSheet.delegate = self;
    [confirmationSheet showInView:self.view];
}

- (void)_applicationDidBecomeActive:(NSNotification *)notification;
{
    [self _reloadLogs];
}

- (void)_reloadLogs;
{
    [self.logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray *logMessages) {
        NSMutableArray *logMessagesWithMinuteSeparators = [NSMutableArray new];
        
        NSDate *previousTimestampDate = nil;
        for (ARKLogMessage *logMessage in logMessages) {
            if (!previousTimestampDate || [logMessage.creationDate timeIntervalSinceDate:previousTimestampDate] > self.minutesBetweenTimestamps * 60.0) {
                NSDateComponents *minuteSeparatorDateComponents = [[[self class] sharedCalendar] components:NSDateComponentUndefined fromDate:logMessage.creationDate];
                minuteSeparatorDateComponents.second = 0;
                minuteSeparatorDateComponents.nanosecond = 0;
                
                NSDate *timestampDate = [minuteSeparatorDateComponents date];
                [logMessagesWithMinuteSeparators addObject:[[ARKTimestampLogMessage alloc] initTimestampMessageWithDate:timestampDate]];
                previousTimestampDate = timestampDate;
            }
            
            [logMessagesWithMinuteSeparators addObject:logMessage];
        }
        
        self.logMessages = logMessagesWithMinuteSeparators;
        [self.tableView reloadData];
    }];
}

- (void)_viewWillAppearForFirstTime:(BOOL)animated;
{
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_openActivitySheet:)];
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

@synthesize text = _text;
@synthesize type = _type;
@synthesize creationDate = _creationDate;

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

- (instancetype)initTimestampMessageWithDate:(NSDate *)date;
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    _text = [[[self class] sharedDateFormatter] stringFromDate:date];
    _type = ARKLogTypeSeparator;
    _creationDate = date;
    
    return self;
}

@end
