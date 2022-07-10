import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:gcp_logger/gcp_logger.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

/// Formats the log data into the proper format for Google Cloud Logging
String formatCloudLoggingLog({
  required Severity severity,
  required String message,
  String? trace,
  String? projectId,
  Map<String, dynamic>? payload,
  Map<String, dynamic>? labels,
  bool? isError,
  Chain? chain,
  Frame? stackFrame,
}) {
  final log = <String, dynamic>{
    if (isError ?? false)
      '@type':
          'type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent',
    ...?payload,
    'severity': severity.toString(),
    'message': message,
    if (trace != null && projectId != null)
      'logging.googleapis.com/trace': 'projects/$projectId/traces/$trace',
    if (labels != null && labels.isNotEmpty)
      'logging.googleapis.com/labels': labels,
    if (chain != null) 'stackTrace': chain.toString().trim(),
    if (stackFrame != null)
      'logging.googleapis.com/sourceLocation':
          frameToSourceInformation(stackFrame),
  };
  return jsonEncode(log);
}

/// Returns a [Frame] from [chain] if possible, otherwise, `null`.
Frame? frameFromChain(
  Chain? chain, {
  List<String> packageExcludeList = const [],
}) {
  if (chain == null || chain.traces.isEmpty) return null;

  final trace = chain.traces.first;
  if (trace.frames.isEmpty) return null;

  final frame = trace.frames.firstWhereOrNull(
    (frame) => !packageExcludeList.contains(frame.package),
  );

  return frame ?? trace.frames.first;
}

/// Formats a [Frame] into source information for Google Cloud logging
@visibleForTesting
Map<String, dynamic> frameToSourceInformation(Frame stackFrame) {
  return <String, dynamic>{
    'file': stackFrame.library,
    if (stackFrame.line != null) 'line': stackFrame.line.toString(),
    'function': stackFrame.member,
  };
}
