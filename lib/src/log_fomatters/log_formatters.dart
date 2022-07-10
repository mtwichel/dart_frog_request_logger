import 'package:gcp_logger/gcp_logger.dart';
import 'package:stack_trace/stack_trace.dart';

export 'gcp_log_formatter.dart';
export 'simple_log_formatter.dart';

/// A function that creates a new log string
typedef LogFormatter = String Function({
  required Severity severity,
  required String message,
  String? trace,
  String? projectId,
  Map<String, dynamic>? payload,
  Map<String, dynamic>? labels,
  bool? isError,
  Chain? chain,
  Frame? stackFrame,
});
