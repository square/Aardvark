//
//  Copyright 2021 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface ARKBugReportAttachment : NSObject

/// Designated initializer.
/// @param fileName File name (including extension) to use when attaching to the email. The file name does not need to be unique among attachments, but should not be empty.
/// @param data Contents of the attachment. Attachments with empty data will be dropped.
/// @param dataMIMEType MIME type of the data. MIME types are as specified by the IANA: <http://www.iana.org/assignments/media-types/>.
- (instancetype)initWithFileName:(NSString *)fileName data:(NSData *)data dataMIMEType:(NSString *)dataMIMEType NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// File name (including extension) to use when attaching to the email.
///
/// The file name does not need to be unique among attachments, but should not be empty.
@property (nonatomic, copy, readonly) NSString *fileName;

/// Contents of the attachment.
///
/// Attachments with empty data will be dropped.
@property (nonatomic, copy, readonly) NSData *data;

/// MIME type of the `data` property.
///
/// MIME types are as specified by the IANA: <http://www.iana.org/assignments/media-types/>.
@property (nonatomic, copy, readonly) NSString *dataMIMEType;

@end

NS_ASSUME_NONNULL_END
