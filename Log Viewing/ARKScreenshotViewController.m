//
//  ARKScreenshotViewController.m
//  Aardvark
//
//  Created by Dan Federman on 10/5/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

#import "ARKScreenshotViewController.h"

#import "UIActivityViewController+ARKAdditions.h"


@interface ARKScreenshotViewController ()

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong, readonly) NSDate *date;
@property (nonatomic, assign, readwrite) BOOL activityViewerPresented;

@end


@implementation ARKScreenshotViewController

#pragma mark - Initialization

- (instancetype)initWithImage:(UIImage *)screenshot date:(NSDate *)date;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _imageView = [[UIImageView alloc] initWithImage:screenshot];
    _date = date;
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapDetected:)];
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.imageView.frame = self.view.bounds;
    self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:self.imageView];
    
    self.title = [NSDateFormatter localizedStringFromDate:self.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.imageView.window addGestureRecognizer:self.tapGestureRecognizer];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_openActivitySheet:)];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Private Methods

- (void)_tapDetected:(UITapGestureRecognizer *)tapRecognizer;
{
    if (tapRecognizer == self.tapGestureRecognizer && tapRecognizer.state == UIGestureRecognizerStateRecognized && !self.activityViewerPresented) {
        CGPoint where = [tapRecognizer locationInView:self.imageView];
        
        // Make sure the user isn't tapping on the navigation bar.
        BOOL userTappedImage = NO;
        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] /* iOS 7 or later */) {
            CGRect navBarFrame = CGRectMake(0.0, 0.0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height + 20.0);
            userTappedImage = !CGRectContainsPoint(navBarFrame, where);
        } else {
            userTappedImage = (where.y > 0.0);
        }
        
        if (userTappedImage) {
            [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
        }
    }
}

- (IBAction)_openActivitySheet:(id)sender;
{
    UIActivityViewController *activityViewController = [UIActivityViewController newAardvarkActivityViewControllerWithItems:@[self.imageView.image]];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([activityViewController respondsToSelector:@selector(completionWithItemsHandler)]) {
        activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            self.activityViewerPresented = NO;
        };
    }
#else
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed){
        self.activityViewerPresented = NO;
    };
#endif
    
    self.activityViewerPresented = YES;
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

@end
