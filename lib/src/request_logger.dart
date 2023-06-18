import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:meta/meta.dart';

/// {@template request_logger}
/// A logger middleware for shelf that formats its messages according to its
/// `logFormatter`
/// {@endtemplate}
class RequestLogger {
  /// {@macro request_logger}
  const RequestLogger({
    required Map<String, String?> headers,
    required LogFormatter logFormatter,
    @visibleForTesting Stdout? testingStdout,
  })  : _headers = headers,
        _logFormatter = logFormatter,
        _testingStdout = testingStdout;

  final LogFormatter _logFormatter;
  final Stdout? _testingStdout;
  final Map<String, String?> _headers;

  /// Log an event with no assigned severity level.
  void normal(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.normal,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event with debug or trace information.
  void debug(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.debug,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event with routine information, such as ongoing status or
  /// performance.
  void info(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.info,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log a normal but significant event, such as start up, shut down, or
  /// a configuration change.
  void notice(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.notice,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event that might cause problems.
  void warning(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.warning,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event that is likely to cause problems.
  void error(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.error,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event that will cause more severe problems or outages.
  void critical(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.critical,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event where a person must take an action immediately.
  void alert(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.alert,
        message,
        payload: payload,
        labels: labels,
      );

  /// Log an event where one or more systems are unusable.
  void emergency(
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
  }) =>
      log(
        Severity.emergency,
        message,
        payload: payload,
        labels: labels,
      );

  /// Write a new log
  void log(
    Severity severity,
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
    StackTrace? stackTrace,
    bool isError = false,
    bool includeStacktrace = false,
    bool includeSourceLocation = true,
    List<String> packageExcludeList = const [
      'dart_frog',
      'shelf',
      'request_logger'
    ],
  }) {
    final _stdout = _testingStdout ?? stdout;
    final chain =
        (stackTrace != null ? Chain.forTrace(stackTrace) : Chain.current())
            .foldFrames(
      (f) => f.isCore || packageExcludeList.contains(f.package),
      terse: true,
    );
    final stackFrame = frameFromChain(
      chain,
      packageExcludeList: packageExcludeList,
    );

    Map<String, dynamic>? payloadMap;
    try {
      payloadMap = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>?;
    } catch (_) {
      payloadMap = {'details': payload.toString()};
    }
    final logString = _logFormatter(
      severity: severity,
      message: message,
      headers: _headers,
      payload: payloadMap,
      labels: labels,
      isError: isError,
      chain: includeStacktrace ? chain : null,
      stackFrame: includeSourceLocation ? stackFrame : null,
    );
    _stdout.writeln(logString);
  }
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
