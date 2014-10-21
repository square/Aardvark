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
#import "ARKLogController.h"
#import "ARKLogMessage.h"
#import "ARKScreenshotViewController.h"
#import "UIActivityViewController+ARKAdditions.h"


@interface ARKLogTableViewController () <UIActionSheetDelegate>

@property (nonatomic, copy, readwrite) NSArray *logMessages;
@property (nonatomic, assign, readwrite) BOOL viewWillAppearForFirstTimeCalled;
@property (nonatomic, assign, readwrite) BOOL hasScrolledToBottom;

@end


@implementation ARKLogTableViewController

#pragma mark - Initialization

- (instancetype)initWithLogController:(ARKLogController *)logController logFormatter:(id <ARKLogFormatter>)logFormatter;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _logController = logController;
    _logFormatter = logFormatter;
    
    return self;
}

- (instancetype)init;
{
    return [self initWithLogController:[ARKLogController defaultController] logFormatter:[ARKDefaultLogFormatter new]];
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)viewDidLayoutSubviews;
{
    [super viewDidLayoutSubviews];
    
    if (!self.hasScrolledToBottom) {
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
        [self.logController clearLogs];
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
    NSAssert(sectionIndex == 0, 0, @"There is only one section index!");
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
    
    ARKLogMessage *firstSeparatorLog = nil;
    for (NSInteger i = index; i >= 0; i--) {
        firstSeparatorLog = self.logMessages[i];
        if (firstSeparatorLog.type == ARKLogTypeSeparator) {
            break;
        }
    }
    
    NSTimeInterval delta = firstSeparatorLog ? [currentLog.creationDate timeIntervalSinceDate:firstSeparatorLog.creationDate] : 0.0;
    if (delta > 60.0) {
        cell.textLabel.text = [NSString stringWithFormat:@"+%.fm\t%@", delta / 60.0, currentLog.text];
    } else if (delta > 1.0) {
        cell.textLabel.text = [NSString stringWithFormat:@"+%.1f\t%@", delta, currentLog.text];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"+0\t%@", currentLog.text];;
    }
    
    UIColor *textColor = nil;
    UIColor *backgroundColor = nil;
    switch (currentLog.type) {
        case ARKLogTypeSeparator:
        {
            static NSCalendar *calendar = nil;
            static dispatch_once_t onceToken = 0;
            dispatch_once(&onceToken, ^{
                calendar = [NSCalendar currentCalendar];
            });
            
            NSCalendarUnit dayComponents = (NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
            NSDateComponents *logDateComponents = [calendar components:dayComponents fromDate:currentLog.creationDate];
            NSDateComponents *todayDateComponents = [calendar components:dayComponents fromDate:[NSDate date]];

            if ([logDateComponents isEqual:todayDateComponents]) {
                // Log was created today.
                cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                       currentLog.text,
                                       [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]];
            } else {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ -- %@",
                                       currentLog.text,
                                       [NSDateFormatter localizedStringFromDate:currentLog.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
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
    self.logMessages = [self.logController allLogMessages];
    [self.tableView reloadData];
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
