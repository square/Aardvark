# Aardvark

[![CI Status](https://img.shields.io/github/workflow/status/square/Aardvark/CI/master)](https://github.com/square/Aardvark/actions?query=workflow%3ACI+branch%3Amaster)
[![Carthage Compatibility](https://img.shields.io/badge/carthage-✓-e2c245.svg)](https://github.com/Carthage/Carthage/)
[![Version](https://img.shields.io/cocoapods/v/Aardvark.svg)](https://cocoapods.org/pods/Aardvark)
[![License](https://img.shields.io/cocoapods/l/Aardvark.svg)](https://cocoapods.org/pods/Aardvark)
[![Platform](https://img.shields.io/cocoapods/p/Aardvark.svg)](https://cocoapods.org/pods/Aardvark)

Aardvark is a library that makes it dead simple to create actionable bug reports.

## Getting started

There are only three steps to get Aardvark logging and bug reporting up and running.

### 1) Install Aardvark.

#### Using [CocoaPods](https://cocoapods.org)

```
platform :ios, '8.0'
pod 'Aardvark'
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

```
github "Square/Aardvark"
```


#### Using Git Submodules

Or manually checkout the submodule with `git submodule add git@github.com:Square/Aardvark.git`, drag Aardvark.xcodeproj to your project, and add Aardvark as a build dependency.

### 2) Setup email bug reporting with a single method call
It is best to do this when you load your application’s UI.

In Swift:

```swift
Aardvark.addDefaultBugReportingGestureWithEmailBugReporter(withRecipient:)
```

In Objective-C:

```objc
[Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:]
```

### 3) Replace calls to `print` with `log`.
In Objective-C, replace calls to `NSLog` with `ARKLog`.

## Reporting Bugs

After doing the above, your users can report a bug by making a two-finger long-press gesture. This gesture triggers a UIAlert asking the user what went wrong. When the user enters this information, an email bug report is generated complete with an attached app screenshot and a text file containing the last 2000 logs. Screenshots are created and stored within Aardvark and do not require camera roll access.

[![Bug Report Flow](BugReportFlow.gif)](BugReportFlow.gif)

Want to look at logs on device? Push an instance of [ARKLogTableViewController](Aardvark/ARKLogTableViewController.h) onto the screen to view your logs.

## Performance
Logs are distributed to loggers on an internal background queue that will never slow down your app. Logs observed by the log store are incrementally appended to disk and not stored in memory.

## Exception Logging
To turn on logging of uncaught exceptions, call `ARKEnableLogOnUncaughtException()`. When an uncaught exception occurs, the stack trace will be logged to the default log distributor. To test this out in the sample app, hold one finger down on the screen for at least 5 seconds.

Once the exception is logged, it will be propogated to any existing uncaught exception handler. By default, the exception will be logged to the default log distributor. To log to a different distributor, call `ARKEnableLogOnUncaughtExceptionToLogDistributor(...)`. You can enable logging to multiple log distributors by calling the method multiple times.

## Customize Aardvark
Want to customize how bug reports are filed? Pass your own object conforming to the [ARKBugReporter](Aardvark/ARKBugReporter.h) protocol and the desired subclass of `UIGestureRecognizer` to `[Aardvark addBugReporter:triggeringGestureRecognizerClass:]`. You can further customize how bug reports will be triggered by modifying the returned gesture recognizer.

Want to change how logs are formatted? Set your own `logFormatter` on the [ARKEmailBugReporter](Aardvark/ARKEmailBugReporter.h) returned from `[Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:]`.

Want to log to the console? `[ARKLogDistributor defaultDistributor].defaultLogStore.printsLogsToConsole = YES;`.

Want different log files for different features? Create an [ARKLogStore](CoreAardvark/ARKLogStore.h) for each feature you want to have its own log file and add them to the default log distributor with `[[[ARKLogDistributor](Logging/ARKLogDistributor.h) defaultDistributor] addLogObserver:featureLogStore]`. Set the `logFilterBlock` on your [ARKLogStore](CoreAardvark/ARKLogStore.h) to make sure only the logs you want are observed by the [ARKLogStore](CoreAardvark/ARKLogStore.h). Use `ARKLogWithType`’s `userInfo` dictionary to specify to which feature a log pertains. See [SampleViewController](AardvarkSample/AardvarkSample/SampleViewController.swift)’s `tapGestureLogStore` for an example.

Want to send your logs to third party services? One log can be easily distributed to multiple services by adding objects conforming to [ARKLogObserver](CoreAardvark/ARKLogObserver.h) to the default [ARKLogDistributor](CoreAardvark/ARKLogDistributor.h) via `addLogObserver:`. [SampleCrashlyticsLogObserver](AardvarkSample/AardvarkSample/SampleCrashlyticsLogObserver.h) is an example of an [ARKLogObserver](CoreAardvark/ARKLogObserver.h) that sends event logs to Crashlytics.

Want to log with Aardvark but don’t want to use Aardvark’s bug reporting tool? Skip step #2 in Getting Started and manually add [ARKLogObserver](CoreAardvark/ARKLogObserver.h) to the default [ARKLogDistributor](CoreAardvark/ARKLogDistributor.h).

## Requirements

* Xcode 8.0 or later
* iOS 8 or later

## Contributing

We’re glad you’re interested in Aardvark, and we’d love to see where you take it. Please read our [contributing guidelines](Contributing.md) prior to submitting a Pull Request.

Thanks, and happy logging!
