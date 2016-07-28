//
//  AardvarkDefines.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
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

/**
 Provides the ability to verify key paths at compile time.
 
 If "keyPath" does not exist, a compile-time error will be generated.
 
 Example:
 // Verifies "isFinished" exists on "operation".
 NSString *key = ARKKeyPath(operation, isFinished);
 
 // Verifies "isFinished" exists on self.
 NSString *key = ARKSelfKeyPath(isFinished);
 
 */
#define ARKKeyPath(object, keyPath) \
    ({ if (NO) { (void)((object).keyPath); } @#keyPath; })

#define ARKSelfKeyPath(keyPath) ARKKeyPath(self, keyPath)


/**
 Throws a caught exception and returns "result" if "condition" is false.
 
 Example:
 ARKCheckCondition(isProperlyConfigured, nil, @"Foo was not properly configured.");
 
 */
#define ARKCheckCondition(condition, result, desc, ...) \
    do { \
        BOOL const conditionResult = !!(condition); \
        if (!conditionResult) { \
            @try { \
                [NSException raise:@"Aardvark API Misuse" format:(desc), ##__VA_ARGS__]; \
            } @catch (NSException *exception) { \
                NSLog(@"Aardvark API Misuse: %s %@", __PRETTY_FUNCTION__, exception.reason); \
                return result;\
            } \
        } \
    } while(0)
