//
//  SampleAppDelegate.h
//  AardvarkSample
//
//  Created by Dan Federman on 10/8/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

@interface SampleAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic, readwrite) UIWindow *window;

@property (strong, nonatomic, readwrite) ARKEmailBugReporter *bugReporter;

@end

