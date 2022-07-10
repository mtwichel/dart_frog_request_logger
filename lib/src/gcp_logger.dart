import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gcp_logger/gcp_logger.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';

/// {@template gcp_logger}
/// A logger middleware for shelf that formats its messages for
/// Google Cloud Logger
/// {@endtemplate}
class GcpLogger {
  /// {@macro gcp_logger}
  const GcpLogger({
    String? traceHeader,
    String? projectId,
    required LogFormatter logFormatter,
    @visibleForTesting Stdout? testingStdout,
  })  : _traceHeader = traceHeader,
        _projectId = projectId,
        _logFormatter = logFormatter,
        _testingStdout = testingStdout;

  final String? _traceHeader;
  final String? _projectId;
  final LogFormatter _logFormatter;
  final Stdout? _testingStdout;

  /// Write a new log
  void log(
    Severity severity,
    String message, {
    Object? payload,
    Map<String, dynamic>? labels,
    StackTrace? stackTrace,
    bool sendToErrorReporting = false,
    bool includeStacktrace = false,
    bool includeSourceLocation = true,
    List<String> packageExcludeList = const [
      'dart_frog',
      'shelf',
      'gcp_logger'
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
    final trace = _traceHeader?.split('/').first;

    final payloadMap = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>?;

    _stdout.writeln(
      _logFormatter(
        severity: severity,
        message: message,
        payload: payloadMap,
        labels: labels,
        projectId: _projectId,
        trace: trace,
        isError: sendToErrorReporting,
        chain: includeStacktrace ? chain : null,
        stackFrame: includeSourceLocation ? stackFrame : null,
      ),
    );
  }

  /// Middleware that injects the cloud logger and automatically logs
  /// uncaught errors
  static Middleware middleware({
    LogFormatter? logFormatter,
    bool shouldLogRequests = false,
    @visibleForTesting
        Future<String> Function() projectIdGetter = currentProjectId,
    @visibleForTesting DateTime Function() nowGetter = DateTime.now,
    @visibleForTesting Stdout? testingStdout,
  }) =>
      (handler) {
        final startTime = nowGetter();
        final _stdout = testingStdout ?? stdout;
        return (request) async {
          final completer = Completer<Response>.sync();

          Request _request;
          GcpLogger _logger;
          try {
            final projectId = await projectIdGetter();
            _logger = GcpLogger(
              projectId: projectId,
              traceHeader: request.headers['X-Cloud-Trace-Context'],
              logFormatter: logFormatter ?? formatCloudLoggingLog,
              testingStdout: testingStdout,
            );
          } on NoProjectIdFoundException catch (e) {
            _logger = GcpLogger(
              logFormatter: logFormatter ?? formatSimpleLog,
              testingStdout: testingStdout,
            )..log(
                Severity.warning,
                e.message,
                includeSourceLocation: false,
              );
          }
          _request = request.change(
            context: {'GcpLogger': () => _logger},
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
                  sendToErrorReporting: true,
                );

                if (shouldLogRequests) {
                  _stdout.writeln(
                    '${startTime.toIso8601String()}\t${_request.method}'
                    '\t[500]\t${request.handlerPath}',
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
                _stdout.writeln(
                  '${startTime.toIso8601String()}\t${_request.method}'
                  '\t[${response.statusCode}]\t${request.handlerPath}',
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

  /// Extracts the [GcpLogger] if injected using the [GcpLogger.middleware]
  static GcpLogger extractLogger(Request request) {
    // ignore: cast_nullable_to_non_nullable
    final loggerGetter = request.context['GcpLogger'] as GcpLogger Function()?;
    if (loggerGetter == null) {
      throw StateError(
        'No GcpLogger found. Did you forget to inject the GcpLogger.middlware?',
      );
    }
    return loggerGetter();
  }
}
