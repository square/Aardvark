//
//  ARKEmailBugReportConfiguration.h
//  Aardvark
//
//  Created by Nick Entin on 4/14/18.
//  Copyright 2018 Square, Inc.
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

#import <Foundation/Foundation.h>

@class ARKLogStore;
@class ARKEmailAttachment;


/// Configuration object describing the contents of an email bug report.
@interface ARKEmailBugReportConfiguration : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

/// The email subject that will be prefilled when the email dialog is presented to the user. Defaults to an empty string.
@property (nonnull, nonatomic, copy) NSString *prefilledEmailSubject;

/// The log stores that will be included as attachments on the email. Defaults to an empty array.
@property (nonnull, nonatomic, copy) NSArray<ARKLogStore *> *logStores;

/// Controls whether or not a screenshot should be attached to the email, when available. Defaults to NO.
@property (nonatomic, readonly) BOOL includesScreenshot;

/// Controls whether or not a view hierarchy description should be attached to the email, when available. Defaults to NO.
@property (nonatomic, readonly) BOOL includesViewHierarchyDescription;

/// Additional attachments to include on the email. Defaults to an empty array.
@property (nonnull, nonatomic, copy) NSArray<ARKEmailAttachment *> *additionalAttachments;

/// Excludes the screenshot from the bug report, if one is included.
- (void)excludeScreenshot;

/// Excludes the view hierarchy description from the bug report, if one is included.
- (void)excludeViewHierarchyDescription;

@end
