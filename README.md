# Aardvark

Aardvark is a library that makes it dead simple to create useful bug reports without leaving your app.

## Usage

There are only three steps to get Aardvark logging and bug reporting up and running.

1) Call `[Aardvark enableDefaultLogController]` to enable logging.

2) Call `[Aardvark addDefaultBugReportingGestureWithBugReportRecipient:]` to enable creating bug reports.

3) Replace `NSLog` with `ARKLog`

This will allow users to report a bug by making a two-finger long-press gesture. This gesture triggers a UIAlert asking the user what went wrong. When the user enters this information, an email bug report is generated complete with an attached app screenshot and a text file containing the last 2000 ARKLogs. Screenshots are created and stored within Aardvark and do not require camera roll access.

You can change how many ARKLogs are included in bug reports by changing the value of `maximumLogCount` on your `defaultController` of `ARKLogController`.

You can customize both how bugs reports are triggered and how they are filed by passing your own `ARKBugReporter` object to `[Aardvark addBugReporter:withTriggeringGestureRecognizerOfClass:]`.

You can easily log to third party services by adding `ARKLogBlock`s to a ARKLogController. Example: `[[ARKLogController defaultController] addLogBlock:^(NSUInteger flags, NSString *logText) { CLSLog(@"%@", logText); } withKey:@"Crashlytics"];`

## Viewing Logs

Push an instance of `ARKLogTableViewController` onto the screen to view your logs. Customize the appearance of your logs by setting your own `logFormatter` on the `ARKLogTableViewController` instance.

If you want ARKLogs to show up in your console, `[ARKLogController defaultController].logToNSLog = YES;`.

## Contributing

We're glad you're interested in Aardvark, and we'd love to see where you take it.

Any contributors to the master Aardvark repository must sign the [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). It's a short form that covers our bases and makes sure you're eligible to contribute.

When you have a change you'd like to see in the master repository, [send a pull request](https://github.com/square/objc-Aardvark/pulls). Before we merge your request, we'll make sure you're in the list of people who have signed a CLA.

Thanks, and happy logging!
