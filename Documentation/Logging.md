# Logging

One of the most helpful components of an actionable bug report is a complete set of logs. Aardvark makes it simple to add logs with the logging utilities in the CoreAardvark framework.

## Getting Started

The easiest way to get started logging with Aardvark is by replacing calls to `print` with `log` in Swift and calls to `NSLog` with `ARKLog` in Objective-C.

```swift
log("Hello world")
```

```objc
ARKLog(@"Hello world");
```

By default, this will log messages to the Aardvark log store _instead of_ the console. If you would like the messages to be logged to the console as well, toggle the default log store's `printsLogsToConsole` property:

```swift
ARKLogDistributor.default().defaultLogStore.printsLogsToConsole = true
```

## Adding Parameters

A recommended pattern for logging is to keep your log messages simple and attach details of the log in the `parameters` field. You can attach key/value pairs of strings to your log messages to provide further debugging data, while keeping your logs easy to scan through in a list of messages.

```swift
log("Said hello to user", parameters: ["user_name": user.name])
```

```objc
ARKLogWithParameters(@{ @"user_name": [user name] }, @"Said hello to user");
```

## Using Dependency Injection

If your app is architected around dependency injection, you can inject an `ARKLogDistributor` instead of using the global logging functions.

```swift
func sayHello(to name: String, on logDistributor: ARKLogDistributor) {
    logDistributor.log("Hello \(name)")
}
```

```objc
- (void)sayHelloToPersonNamed:(NSString *)name onLogDistributor:(ARKLogDistributor *)logDistributor;
{
    [logDistributor logWithFormat:@"Hello %@", name];
}
```

## Using Multiple Log Stores

By default, all logs are sent to the same log file. If you would prefer to send some logs into separate log files, you can add multiple log stores to the distributor and set each store's `logFilterBlock` to filter incoming logs.

To facilitate filtering, log messages contain a `userInfo` dictionary. Unlike the `parameters` dictionary, the `userInfo` is not persisted with the log message.

```swift
log("Loaded data", userInfo: ["category": "Core Data"])
```

For example, we can set up a second log store for all of the logs related to Core Data that is separate from the rest of the logs. This could be helpful if our Core Data implementation consistently runs tasks in the background and creates noise in the main log store.

```swift
// Create the new log store.
let coreDataLogStore = ARKLogStore(persistedLogFileName: "CoreDataLogs.data")

// Set the new log store to only include logs related to Core Data.
coreDataLogStore.logFilterBlock = { message in
    return message.userInfo?["category"] == "Core Data"
}

// Add the new log store to the default distributor.
ARKLogDistributor.default().add(coreDataLogStore)

// Set the default log store to exclude log related to Core Data.
ARKLogDistributor.default().defaultLogStore.logFilterBlock = { message in
    return message.userInfo?["category"] != "Core Data"
}
```

See [SampleViewController](../AardvarkSample/AardvarkSample/SampleViewController.swift)’s `tapGestureLogStore` for an example of how this works.

## Sending Logs to Other Services

One log can be easily distributed to multiple services by adding objects conforming to [ARKLogObserver](../Sources/CoreAardvark/Logging/ARKLogObserver.h) to the default [ARKLogDistributor](../Sources/CoreAardvark/Logging/ARKLogDistributor.h) via `addLogObserver:`. [SampleCrashlyticsLogObserver](../AardvarkSample/AardvarkSample/SampleCrashlyticsLogObserver.h) is an example of an [ARKLogObserver](../Sources/CoreAardvark/Logging/ARKLogObserver.h) that sends event logs to Crashlytics.

## Formatting Logs

When logs are shown in the in-app log viewer or attached to a bug report email, they are formatted into plain text. You can change how these messages look by creating a formatter that conforms to [ARKLogFormatter](../Sources/CoreAardvark/Logging/ARKLogFormatter.h) and setting it as the formatter where desired (e.g. as the `logFormatter` on an [ARKEmailBugReporter](../Sources/AardvarkMailUI/ARKEmailBugReporter.h)).
