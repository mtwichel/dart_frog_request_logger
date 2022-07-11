import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:request_logger/request_logger.dart';
import 'package:shelf/shelf.dart';

/// {@template request_logger}
/// A logger middleware for shelf that formats its messages according to its
/// `logFormatter`
/// {@endtemplate}
class RequestLogger {
  /// {@macro request_logger}
  const RequestLogger({
    required Request request,
    required LogFormatter logFormatter,
    @visibleForTesting Stdout? testingStdout,
  })  : _request = request,
        _logFormatter = logFormatter,
        _testingStdout = testingStdout;

  final Request _request;
  final LogFormatter _logFormatter;
  final Stdout? _testingStdout;

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

    final payloadMap = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>?;
    final logString = _logFormatter(
      severity: severity,
      message: message,
      request: _request,
      payload: payloadMap,
      labels: labels,
      isError: isError,
      chain: includeStacktrace ? chain : null,
      stackFrame: includeSourceLocation ? stackFrame : null,
    );

    _stdout.writeln(logString);
  }

  /// Middleware that injects `a` RequestLogger and automatically logs
  /// uncaught errors
  static Middleware middleware({
    required LogFormatter logFormatter,
    bool shouldLogRequests = false,
    @visibleForTesting DateTime Function() nowGetter = DateTime.now,
    @visibleForTesting Stdout? testingStdout,
  }) =>
      (handler) {
        final startTime = nowGetter();
        final _stdout = testingStdout ?? stdout;
        return (request) async {
          final completer = Completer<Response>.sync();

          Request _request;
          RequestLogger _logger;

          _logger = RequestLogger(
            request: request,
            logFormatter: logFormatter,
            testingStdout: testingStdout,
          );

          _request = request.change(
            context: {'RequestLogger': () => _logger},
          );

          Zone.current.fork(
            specification: ZoneSpecification(
              handleUncaughtError: (self, parent, _zone, error, stackTrace) {
                if (error is HijackException) {
                  completer.completeError(error, stackTrace);
                }
                if (completer.isCompleted) {
                  return;
                }

                _logger.log(
                  Severity.error,
                  error.toString().trim(),
                  stackTrace: stackTrace,
                  includeStacktrace: true,
                  isError: true,
                );

                if (shouldLogRequests) {
                  _logger.log(
                    Severity.info,
                    '${startTime.toIso8601String()}\t${_request.method}'
                    '\t[500]\t${request.handlerPath}',
                    includeSourceLocation: false,
                  );
                }

                completer.complete(
                  Response(
                    HttpStatus.internalServerError,
                    body: 'Internal Server Error',
                  ),
                );
              },
            ),
          ).runGuarded(
            () async {
              final response = await handler(_request);
              if (shouldLogRequests) {
                _logger.log(
                  Severity.info,
                  '${startTime.toIso8601String()}\t${_request.method}'
                  '\t[500]\t${request.handlerPath}',
                  includeSourceLocation: false,
                );
              }
              if (!completer.isCompleted) {
                completer.complete(response);
              }
            },
          );

          return completer.future;
        };
      };

  /// Extracts the [RequestLogger] if injected using the
  /// [RequestLogger.middleware]
  static RequestLogger extractLogger(Request request) {
    // ignore: cast_nullable_to_non_nullable
    final loggerGetter =
        request.context['RequestLogger'] as RequestLogger Function()?;
    if (loggerGetter == null) {
      throw StateError(
        'No RequestLogger found. '
        'Did you forget to inject the RequestLogger.middlware?',
      );
    }
    return loggerGetter();
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
