//
//  AppDelegate.m
//  AardvarkViewerMac
//
//  Created by Robert Gilliam on 1/29/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//

#import <AardvarkMac/Aardvark-Mac.h>
#import <AardvarkMac/NSURL+ARKAdditions.h>

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *filePathToTranslateLabel;
@end


@implementation AppDelegate

- (NSURL *)inputDataFileURL;
{
    // temporarily return hardcoded
    return [NSURL fileURLWithPath:@"/Users/rhg/Downloads/6SMYYTGHWKB59 - Application Support/HQLogModuleCardReaderDriversLogs.data"];
    
    // TODO: replace with file picker component
}

- (NSURL *)outputTextFileURL;
{
    // TODO: transform from input data file or show file picker (possibly with default)
    NSURL *inputDataFileURL = [self inputDataFileURL];
    return [[inputDataFileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"txt"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    // Copy the input data to application support, where it can be used to create a log store.
    NSURL *inputDataFileURL = [self inputDataFileURL];
    NSURL *inputDataInApplicationSupportFileURL = [NSURL ARK_fileURLWithApplicationSupportFilename:inputDataFileURL.lastPathComponent];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:[inputDataInApplicationSupportFileURL path]]) {
        NSError *error = nil;
        
        BOOL successfullyDeleted = [fileManager removeItemAtURL:inputDataInApplicationSupportFileURL error:&error];
        if (!successfullyDeleted) {
            NSLog(@"Failed to delete old temporary data with err: %@", error);
            abort();
        }
    }
    
    NSError *error = nil;
    BOOL successfullyCopied = [fileManager copyItemAtURL:inputDataFileURL toURL:inputDataInApplicationSupportFileURL error:&error];
    if (!successfullyCopied) {
        NSLog(@"Failed to copy with err: %@", error);
        abort();
    }
    
    ARKLogStore *logStore = [[ARKLogStore alloc] initWithPersistedLogFileName:[inputDataInApplicationSupportFileURL lastPathComponent] maximumLogMessageCount:NSUIntegerMax];
    [ARKLogDistributor defaultDistributor].defaultLogStore = logStore;
    
    [logStore retrieveAllLogMessagesWithCompletionHandler:^(NSArray * _Nonnull logMessages) {
        [self _onLogMessagesRetrieved:logMessages];
    }];
}

- (void)_onLogMessagesRetrieved:(NSArray *)logMessages;
{
    NSURL *outputURL = [self outputTextFileURL];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL emptyFileSuccessfullyCreated = [fileManager createFileAtPath:[outputURL path] contents:nil attributes:nil];
    if (!emptyFileSuccessfullyCreated) {
        NSLog(@"Failed to create empty file at output path.");
        abort();
    }
    
    // Open a file for writing.
    NSError *error = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:outputURL error:&error];
    if (!fileHandle) {
        NSLog(@"Failed to open file handle with err: %@", error);
        abort();
    }
    
    id <ARKLogFormatter> logFormatter = [[ARKDefaultLogFormatter alloc] init];
    for (ARKLogMessage *aMessage in logMessages) {
        NSString *logMessageString = [logFormatter formattedLogMessage:aMessage];
        logMessageString = [logMessageString stringByAppendingString:@"\n"];
        NSData *data = [logMessageString dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandle writeData:data];
    }
    
    [fileHandle closeFile];
    
    NSLog(@"DONE!");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification;
{
    // Insert code here to tear down your application
}

- (IBAction)pickFile:(id)sender {
    
}
- (IBAction)translate:(id)sender {
    
}

@end
