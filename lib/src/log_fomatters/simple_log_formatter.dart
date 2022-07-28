import 'dart:convert';

import 'package:request_logger/request_logger.dart';

/// Formats the log data into a simple format for local output logging
LogFormatter formatSimpleLog() => ({
      required Severity severity,
      required String message,
      required Map<String, String?> headers,
      Map<String, dynamic>? payload,
      Map<String, dynamic>? labels,
      bool? isError,
      Chain? chain,
      Frame? stackFrame,
    }) {
      final buffer = StringBuffer()..write('[$severity] $message');
      if (stackFrame != null) {
        buffer
          ..writeln()
          ..write('  ')
          ..write(stackFrame.library)
          ..write(':')
          ..write(stackFrame.line)
          ..write(':')
          ..write(stackFrame.column)
          ..write(' (')
          ..write(stackFrame.member)
          ..write(')');
      }

      if (labels != null) {
        buffer
          ..writeln()
          ..write('  Labels: ')
          ..write(jsonEncode(labels));
      }
      if (payload != null) {
        buffer
          ..writeln()
          ..write('  Payload: ')
          ..write(jsonEncode(payload));
      }
      if (chain != null) {
        buffer
          ..writeln()
          ..write(chain.toString().trim());
      }

      return buffer.toString();
    };
