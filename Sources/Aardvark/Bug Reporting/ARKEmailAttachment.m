//
//  ARKEmailAttachment.m
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

#import "ARKEmailAttachment.h"


@implementation ARKEmailAttachment

- (instancetype)initWithFileName:(NSString *)fileName data:(NSData *)data dataMIMEType:(NSString *)dataMIMEType;
{
    self = [super init];
    
    _fileName = [fileName copy];
    _data = [data copy];
    _dataMIMEType = [dataMIMEType copy];
    
    return self;
}

@end
