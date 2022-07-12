// ignore_for_file: unnecessary_lambdas

import 'package:mocktail/mocktail.dart';
import 'package:request_logger/request_logger.dart';
import 'package:request_logger/src/log_fomatters/log_formatters.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../_helpers/_helpers.dart';

const projectId = 'projectId';

void main() {
  group('formatCloudLoggingLog', () {
    late Request request;
    setUp(() {
      request = MockShelfRequest();
      when(() => request.context).thenReturn({});
      when(() => request.headers).thenReturn({});
    });
    test('returns base log correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          request: request,
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );
    });
    test('returns log with payload correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          request: request,
          payload: {'test': 'test'},
        ),
        {'severity': 'ALERT', 'message': 'message', 'test': 'test'},
      );
    });
    test('returns log that should go to error reporting correctly', () {
      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          request: request,
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
            request: request,
          ),
          {'severity': 'ALERT', 'message': 'message'},
        );
      });
      test('when trace is present', () {
        when(() => request.headers)
            .thenReturn({'X-Cloud-Trace-Context': 'trace/1'});
        expectJson(
          formatCloudLoggingLog(projectId: projectId)(
            severity: Severity.alert,
            message: 'message',
            request: request,
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
          request: request,
          labels: {},
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );

      expectJson(
        formatCloudLoggingLog(projectId: projectId)(
          severity: Severity.alert,
          message: 'message',
          request: request,
          labels: {'test': 'test'},
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
          request: request,
          chain: chain,
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
          request: request,
          stackFrame: stackFrame,
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
