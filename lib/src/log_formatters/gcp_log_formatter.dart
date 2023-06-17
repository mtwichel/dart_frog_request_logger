import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:request_logger/request_logger.dart';

/// Formats the log data into the proper format for Google Cloud Logging
LogFormatter formatCloudLoggingLog({required String projectId}) => ({
      required Severity severity,
      required String message,
      required Map<String, String?> headers,
      Map<String, dynamic>? payload,
      Map<String, dynamic>? labels,
      bool? isError,
      Chain? chain,
      Frame? stackFrame,
    }) {
      final trace = headers['X-Cloud-Trace-Context']?.split('/').first;

      final log = <String, dynamic>{
        if (isError ?? false)
          '@type':
              'type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent',
        ...?payload,
        'severity': severity.toString(),
        'message': message,
        if (trace != null)
          'logging.googleapis.com/trace': 'projects/$projectId/traces/$trace',
        if (labels != null && labels.isNotEmpty)
          'logging.googleapis.com/labels': labels,
        if (chain != null) 'stackTrace': chain.toString().trim(),
        if (stackFrame != null)
          'logging.googleapis.com/sourceLocation':
              frameToSourceInformation(stackFrame),
      };
      return jsonEncode(log);
    };

/// Formats a [Frame] into source information for Google Cloud logging
@visibleForTesting
Map<String, dynamic> frameToSourceInformation(Frame stackFrame) {
  return <String, dynamic>{
    'file': stackFrame.library,
    if (stackFrame.line != null) 'line': stackFrame.line.toString(),
    'function': stackFrame.member,
  };
}
