//
//  AardvarkDefines.h
//  Aardvark
//
//  Created by Dan Federman on 10/4/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
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
 Throws a caught exception and returns "return_statement" if "condition" is false.
 
 Example:
 ARKCheckCondition(isProperlyConfigured, nil, @"Foo was not properly configured.");
 
 */
#define ARKCheckCondition(condition, result, desc, ...) \
    do { \
        const BOOL conditionResult = !!(condition); \
        if (!conditionResult) { \
            @try { \
                NSAssert(conditionResult, (desc), ##__VA_ARGS__); \
            } @catch (NSException *exception) { \
                NSLog(@"Aardvark API Misuse: %s %@", __PRETTY_FUNCTION__, exception.reason); \
                return result;\
            } \
        } \
    } while(0)
