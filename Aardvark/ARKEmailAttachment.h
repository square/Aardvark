//
//  ARKEmailAttachment.h
//  Aardvark
//
//  Created by Nick Entin on 1/10/18.
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


@interface ARKEmailAttachment : NSObject

- (nonnull instancetype)initWithFileName:(nonnull NSString *)fileName data:(nonnull NSData *)data dataMIMEType:(nonnull NSString *)dataMIMEType;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

/// File name (including extension) to use when attaching to the email. This does not need to be unique among attachments, but should not be empty.
@property (nonnull, nonatomic, copy, readonly) NSString *fileName;

/// Contents of the attachment. Attachments with empty data will be dropped.
@property (nonnull, nonatomic, copy, readonly) NSData *data;

/// MIME type of `data` property. MIME types are as specified by the IANA: http://www.iana.org/assignments/media-types/
@property (nonnull, nonatomic, copy, readonly) NSString *dataMIMEType;

@end
