# Request Logger 🪵
[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A middleware for [shelf](https://pub.dev/packages/shelf) and [dart_frog](https://verygoodopensource.github.io/dart_frog/) that helps write logs.

## Features ✨
- 🎯🐸 Works out of the box with [Dart Frog](https://verygoodopensource.github.io/dart_frog/) and [Shelf](https://pub.dev/packages/shel) 🗄️.
- ☁️ Built-in support for console-based logs & [Google Cloud Logging](https://cloud.google.com/logging).
- 💉 Automatically injects the logger into your request handlers.
- 🐛 Automatically logs uncaught errors.
- 📋 Includes a ton of debugging information, including stacktraces.
- 🧪 100% code coverage verified with [Very Good Workflows](https://github.com/VeryGoodOpenSource/very_good_workflows).

## Quickstart 🚀  

### Using Dart Frog 🎯🐸
This is a simplified example. For a full example visit [`/examples/dart_frog`](https://github.com/mtwichel/request_logger/tree/main/examples/dart_frog)
#### Setup 🏗️

Add the `RequestLogger` middlware in your top level `_middlware.dart` file.
```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:request_logger/request_logger.dart';
import 'package:request_logger/log_formatters.dart';

Handler middleware(Handler handler) {
  return handler.use(
    fromShelfMiddleware(
      RequestLogger.middleware(logFormatter: formatSimpleLog()),
    ),
  );
}
```

#### Write Logs 📝

Read the `RequestLogger` from the `RequestContext`.
```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:request_logger/request_logger.dart';

Response onRequest(RequestContext context) {
  final logger = context.read<RequestLogger>();
  logger.debug('Hello Logs');
  return Response();
}
```

### Using Shelf 🗄️
This is a simplified example. For a full example visit [`/examples/shelf`](https://github.com/mtwichel/request_logger/tree/main/examples/shelf)
#### Setup 🏗️

Add the `RequestLogger` middlware in your `Pipeline`.
```dart
import 'package:request_logger/request_logger.dart';
import 'package:request_logger/log_formatters.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void main() {
  final handler = Pipeline()
      .addMiddleware(RequestLogger.middleware(logFormatter: formatSimpleLog()))
      .addHandler(_router);
  await serve(handler, ip, port);
}
```

#### Write Logs 📝

Read the `RequestLogger` by extracting it from the `Request`.
```dart
import 'package:request_logger/request_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Response _handler(Request request) {
  final logger = RequestLogger.extractLogger(request);
  logger.debug('Hello Logs');

  return Response.ok('Hello, World!\n');
}
```

## Using Different Log Formats

Request logger supports log formats by providing a different `LogFormatter` when adding your middleware. You can either provide your own or use one of the built-in formatters.

### Built-in Formatters
All of the built in log formats live under `package:request_logger/log_formatters.dart`.

The built-in loggers currently are:
- `formatSimpleLog()`: Formats a log with no particular specification - great for local development.
- `formatCloudLoggingLog()`: Formats a log for [Google Cloud Logging](https://cloud.google.com/logging)

### Make You Own Formatter
You can make your own formatter for your own specification! Just make sure it returns a `String`.

Example:
```dart
LogFormatter formatMyCustomLog() => ({
      required Severity severity,
      required String message,
      required Request request,
      Map<String, dynamic>? payload,
      Map<String, dynamic>? labels,
      bool? isError,
      Chain? chain,
      Frame? stackFrame,
    }) {
      return 'My custom log: $message';
    };
```

[ci_badge]: https://github.com/mtwichel/request_logger/actions/workflows/request_logger_verify_and_test.yaml/badge.svg
[ci_link]: https://github.com/mtwichel/request_logger/actions/workflows/request_logger_verify_and_test.yaml
[coverage_badge]: https://raw.githubusercontent.com/mtwichel/request_logger/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
