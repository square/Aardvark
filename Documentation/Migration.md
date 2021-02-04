# Migrating Between Versions

## Migrating from Aardvark 3.x / CoreAardvark 2.x

The biggest change in the Aardvark 4.0 family is the reorganization of files between frameworks. This release introduced two new frameworks: AardvarkMailUI and AardvarkLoggingUI. Both of these frameworks were released with a version number of 1.0. You will likely need to update your dependencies to include one or more of these new frameworks, depending which components of Aardvark you were previously using.

In addition, there are a handful of breaking changes in the API:

* `ARKEmailAttachment` was renamed to `ARKBugReportAttachment`.
* `ARKEmailBugReporter.attachesViewHierarchyDescriptionWithScreenshot` was renamed to `ARKEmailBugReporter.attachesViewHierarchyDescription`. This also represents a change in when the view hierarchy is attached (it no longer depends on the screenshot also being attached).
* The initializer for `ARKLogMessage` now takes an additional `parameters` argument. This allows for attaching a persisted string dictionary to the log message.
