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
