import 'package:request_logger/request_logger.dart';

/// A function that formats a new log string.
///
/// - [severity]: The severity level of a log
/// - [message]: The message to be logged
/// - [request]: the request making the log
/// - [payload]: An optional data object attached to this log
/// - [labels]: Optional labels to identify this log
/// - [isError]: True if this log should be considered an error,
///   such as reporting to an error monitoring service
/// - [chain]: A chain that can be printed as a stacktrace using `toString()`.
///   Will be set if available.
/// - [stackFrame]: The top frame in the stacktrace, which represents the frame
///   that called the logger. Will be set if available.
typedef LogFormatter = String Function({
  required Severity severity,
  required String message,
  required Map<String, String?> headers,
  Map<String, dynamic>? payload,
  Map<String, dynamic>? labels,
  bool? isError,
  Chain? chain,
  Frame? stackFrame,
});
