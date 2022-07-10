# Google Cloud Platform Logger ☁️🪵
[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A middleware for [shelf](https://pub.dev/packages/shelf) and [dart_frog](https://verygoodopensource.github.io/dart_frog/) that helps write logs to [Google Cloud Logging](https://cloud.google.com/logging).

## Features ✨
- 🎯🐸 Works out of the box with [Dart Frog](https://verygoodopensource.github.io/dart_frog/) and [Shelf](https://pub.dev/packages/shel) 🗄️.
- 👷 Set up in one line of code.
- 💉 Automatically injects the logger into your request handlers.
- 🐛 Supplied middleware automatically logs uncaught errors and reports the to [Error Reporting](https://cloud.google.com/error-reporting).
- 💻 Simple logger for local development.
- 📋 Includes a ton of debugging information, including source locations and stacktraces.
- 🧪 100% code coverage verified with [Very Good Workflows](https://github.com/VeryGoodOpenSource/very_good_workflows).

## Quickstart 🚀

### Using Dart Frog 🎯🐸
This is a simplified example. For a full example visit `/examples/dart_frog`
#### Setup 🏗️

Add the `GcpLogger` middlware in your top level `_middlware.dart` file.
```dart
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(fromShelfMiddleware(GcpLogger.middleware()));
}
```

#### Write Logs 📝

Read the `GcpLogger` from the `RequestContext`.
```dart
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  final logger = context.read<GcpLogger>();
  logger.debug('Hello Logs');
  return Response();
}
```

### Using Shelf 🗄️
This is a simplified example. For a full example visit `/examples/shelf`
#### Setup 🏗️

Add the `GcpLogger` middlware in your `Pipeline`.
```dart
import 'package:gcp_logger/gcp_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void main() {
final handler = Pipeline().addMiddleware(GcpLogger.middleware()).addHandler(_router);
await serve(handler, ip, port);
}
```

#### Write Logs 📝

Read the `GcpLogger` by extracting it from the `Request`.
```dart
import 'package:gcp_logger/gcp_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Response _handler(Request request) {
  final logger = GcpLogger.extractLogger(request);
  logger.debug('Hello Logs');

  return Response.ok('Hello, World!\n');
}
```

[ci_badge]: https://github.com/mtwichel/gcp_logger/actions/workflows/gcp_logger_verify_and_test.yaml/badge.svg
[ci_link]: https://github.com/mtwichel/gcp_logger/actions/workflows/gcp_logger_verify_and_test.yaml
[coverage_badge]: https://raw.githubusercontent.com/mtwichel/gcp_logger/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
