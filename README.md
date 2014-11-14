# Aardvark

Aardvark is a threadsafe library that makes it dead simple to create actionable bug reports within your app without impacting impacting performance.

## Usage

There are only two steps to get Aardvark logging and bug reporting up and running.

1) Call `[Aardvark addDefaultBugReportingGestureWithEmailBugReporterWithRecipient:]` to enable the creation of email bug reports.

2) Replace `NSLog` with `ARKLog`

This will allow users to report a bug by making a two-finger long-press gesture. This gesture triggers a UIAlert asking the user what went wrong. When the user enters this information, an email bug report is generated complete with an attached app screenshot and a text file containing the last 2000 ARKLogs. Screenshots are created and stored within Aardvark and do not require camera roll access.

You can change how many ARKLogs are included in bug reports by changing the value of `maximumLogMessageCount` on the `defaultLogStore` of `ARKLogDistributor`.

You can customize both how bug reports are triggered and how they are formatted by passing your own `ARKBugReporter` object and the desired subclass class of `UIGestureRecognizer` to `[Aardvark addBugReporter:withTriggeringGestureRecognizerOfClass:]`. You can further customize how bug reports will be triggered by modifying the returned gesture recognizer.

You can easily log to third party services by adding `ARKLogConsumer`s to a ARKLogDistributor. SampleCrashlyticsLogHandler is an example of a ARKLogConsumer that logs events to Crashlytics.

## Viewing Logs

Push an instance of `ARKLogTableViewController` onto the screen to view your logs. Customize the appearance of your logs by setting your own `logFormatter` on the `ARKLogTableViewController` instance.

If you want ARKLogs to show up in your console, `[ARKLogDistributor defaultLogStore].logToConsole = YES;`.

## Contributing

We're glad you're interested in Aardvark, and we'd love to see where you take it.

Any contributors to the master Aardvark repository must sign the [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). It's a short form that covers our bases and makes sure you're eligible to contribute.

When you have a change you'd like to see in the master repository, [send a pull request](https://github.com/square/objc-Aardvark/pulls). Before we merge your request, we'll make sure you're in the list of people who have signed a CLA.

Thanks, and happy logging!
