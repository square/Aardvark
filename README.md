# Aardvark

Aardvark is a library that makes it dead simple to create actionable bug reports.

## Getting started

There are only three steps to get Aardvark logging and bug reporting up and running.

1) Install with [CocoaPods](http://cocoapods.org)

```
platform :ios, '6.0'
pod 'Aardvark'
```
Or manually checkout the submodule with `git submodule add git@github.com:Square/objc-Aardvark.git`, drag Aardvark.xcodeproj to your project and add Aardvark as a build dependency.

2) Call `[Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:]` to enable the creation of email bug reports. It is best to do this when you load your application's UI.

3) Replace calls to `NSLog` with `ARKLog`. `ARKLog` has exactly the same syntax as `NSLog`.

## Reporting Bugs

After doing the above, your users can report a bug by making a two-finger long-press gesture. This gesture triggers a UIAlert asking the user what went wrong. When the user enters this information, an email bug report is generated complete with an attached app screenshot and a text file containing the last 2000 logs. Screenshots are created and stored within Aardvark and do not require camera roll access.

Want to look at logs on device? Push an instance of [ARKLogTableViewController](Log%20Viewing/ARKLogTableViewController.h) onto the screen to view your logs.

## Performance
Logs are distributed to loggers on an internal background queue that will never slow down your app. Logs observed by the log store are incrementally appended to disk and not stored in memory.

## Customize Aardvark
Want to customize how bug reports are filed? Pass your own object conforming to the [ARKBugReporter](Bug%20Reporting/ARKBugReporter.h) protocol and the desired subclass class of `UIGestureRecognizer` to `[Aardvark addBugReporter:triggeringGestureRecognizerClass:]`. You can further customize how bug reports will be triggered by modifying the returned gesture recognizer.

Want to change how logs are formatted? Set your own `logFormatter` on the [ARKEmailBugReporter](Bug%20Reporting/ARKEmailBugReporter.h) returned from `[Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:]`.

Want to log to the console? `[ARKLogDistributor defaultDistributor].defaultLogStore.printsLogsToConsole = YES;`.

Want different log files for different features? Create an [ARKLogStore](Logging/ARKLogStore.h) for each feature you want to have its own log file and add them to the default log distributor with `[[[ARKLogDistributor](Logging/ARKLogDistributor.h) defaultDistributor] addLogObserver:featureLogStore]`. Set the `logFilterBlock` on your [ARKLogStore](Logging/ARKLogStore.h) to make sure only the logs you want are observed by the [ARKLogStore](Logging/ARKLogStore.h). Use `ARKLogWithType`'s `userInfo` dictionary to specify to which feature a log pertains. See [SampleViewController](AardvarkSample/AardvarkSample/SampleViewController.m)'s `tapGestureLogStore` for an example.

Want to send your logs to third party services? One log can be easily distributed to multiple loggers by adding objects conforming to [ARKLogObserver](Logging/ARKLogObserver.h)s to the default [ARKLogDistributor](Logging/ARKLogDistributor.h) via `addLogObserver:`. [SampleCrashlyticsLogObserver](AardvarkSample/AardvarkSample/SampleCrashlyticsLogObserver.h) is an example of an [ARKLogObserver](Logging/ARKLogObserver.h) that logs events to Crashlytics.

Want to log with Aardvark but don't want to use Aardvark's bug reporting tool? Skip step #2 in Getting Started and manually add [ARKLogObserver](Logging/ARKLogObserver.h)s to the default [ARKLogDistributor](Logging/ARKLogDistributor.h).

## Requirements

* Xcode 5 or later
* iOS 6 or later

## Contributing

We're glad you're interested in Aardvark, and we'd love to see where you take it.

Any contributors to the master Aardvark repository must sign the [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). It's a short form that covers our bases and makes sure you're eligible to contribute.

When you have a change you'd like to see in the master repository, [send a pull request](https://github.com/square/objc-Aardvark/pulls). Before we merge your request, we'll make sure you're in the list of people who have signed a CLA.

Thanks, and happy logging!
