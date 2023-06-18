// ignore_for_file: unnecessary_lambdas

import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:dart_frog_request_logger/log_formatters.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../_helpers/_helpers.dart';

const projectId = 'projectId';

void main() {
  group('formatCloudLoggingLog', () {
    test('returns base log correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          headers: {},
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );
    });
    test('returns log with payload correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          payload: {'test': 'test'},
          headers: {},
        ),
        {'severity': 'ALERT', 'message': 'message', 'test': 'test'},
      );
    });
    test('returns log that should go to error reporting correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          headers: {},
          isError: true,
        ),
        {
          'severity': 'ALERT',
          'message': 'message',
          '@type':
              'type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent',
        },
      );
    });
    group('returns log with trace information correctly', () {
      test('when trace header is missing', () {
        expectJson(
          formatCloudLoggingLog(projectId: projectId)(
            severity: Severity.alert,
            message: 'message',
            headers: {},
          ),
          {'severity': 'ALERT', 'message': 'message'},
        );
      });
      test('when trace is present', () {
        expectJson(
          formatCloudLoggingLog(projectId: projectId)(
            severity: Severity.alert,
            message: 'message',
            headers: {'X-Cloud-Trace-Context': 'trace/1'},
          ),
          {
            'severity': 'ALERT',
            'message': 'message',
            'logging.googleapis.com/trace': 'projects/projectId/traces/trace'
          },
        );
      });
    });
    test('returns log with labels correctly', () {
      // empty labels shouldn't be added
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          labels: {},
          headers: {},
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );

      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          labels: {'test': 'test'},
          headers: {},
        ),
        {
          'severity': 'ALERT',
          'message': 'message',
          'logging.googleapis.com/labels': {'test': 'test'}
        },
      );
    });

    test('returns log with chain correctly', () {
      final chain = MockChain();
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          chain: chain,
          headers: {},
        ),
        {'severity': 'ALERT', 'message': 'message', 'stackTrace': 'chain'},
      );
    });
    test('returns log with stackFrame correctly', () {
      final stackFrame = MockFrame();
      when(() => stackFrame.library).thenReturn('file');
      when(() => stackFrame.line).thenReturn(1);
      when(() => stackFrame.member).thenReturn('function');
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          stackFrame: stackFrame,
          headers: {},
        ),
        {
          'severity': 'ALERT',
          'message': 'message',
          'logging.googleapis.com/sourceLocation':
              frameToSourceInformation(stackFrame)
        },
      );
    });
  });

  group('frameToSourceInformation', () {
    test('returns correctly', () {
      final frame = MockFrame();
      when(() => frame.library).thenReturn('file');
      when(() => frame.line).thenReturn(1);
      when(() => frame.member).thenReturn('function');

      expect(
        frameToSourceInformation(frame),
        {
          'file': 'file',
          'line': '1',
          'function': 'function',
        },
      );
    });
  });
}
