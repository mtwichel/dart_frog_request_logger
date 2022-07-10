// ignore_for_file: unnecessary_lambdas

import 'package:gcp_logger/gcp_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../_helpers/_helpers.dart';

void main() {
  group('formatCloudLoggingLog', () {
    test('returns base log correctly', () {
      expectJson(
        formatCloudLoggingLog(severity: Severity.alert, message: 'message'),
        {'severity': 'ALERT', 'message': 'message'},
      );
    });
    test('returns log with payload correctly', () {
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
          payload: {'test': 'test'},
        ),
        {'severity': 'ALERT', 'message': 'message', 'test': 'test'},
      );
    });
    test('returns log that should go to error reporting correctly', () {
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
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
    test('returns log with trace information correctly', () {
      // project id missing
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
          trace: 'trace',
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );
      // trace missing
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
          projectId: 'project',
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );
      // project id and trace included
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
          trace: 'trace',
          projectId: 'project',
        ),
        {
          'severity': 'ALERT',
          'message': 'message',
          'logging.googleapis.com/trace': 'projects/project/traces/trace'
        },
      );
    });
    test('returns log with labels correctly', () {
      // empty labels shouldn't be added
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
          labels: {},
        ),
        {'severity': 'ALERT', 'message': 'message'},
      );
      expectJson(
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
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
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
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
        formatCloudLoggingLog(
          severity: Severity.alert,
          message: 'message',
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
  group('frameFromChain', () {
    test('returns null if chain is null or empty', () {
      expect(frameFromChain(null), null);
      final chain = MockChain();
      when(() => chain.traces).thenReturn([]);
      expect(frameFromChain(chain), null);
    });

    test('returns null if first trace is empty', () {
      final chain = MockChain();
      final trace = MockTrace();
      when(() => chain.traces).thenReturn([trace]);
      when(() => trace.frames).thenReturn([]);
      expect(frameFromChain(chain), null);
    });

    test('returns first frame that is not excluded', () {
      final chain = MockChain();
      final trace = MockTrace();
      final frame1 = MockFrame();
      final frame2 = MockFrame();
      when(() => chain.traces).thenReturn([trace]);
      when(() => trace.frames).thenReturn([frame1, frame2]);
      when(() => frame1.package).thenReturn('excluded');
      when(() => frame2.package).thenReturn('included');
      expect(frameFromChain(chain, packageExcludeList: ['excluded']), frame2);
    });

    test('returns first frame that if all frames excluded', () {
      final chain = MockChain();
      final trace = MockTrace();
      final frame1 = MockFrame();
      final frame2 = MockFrame();
      when(() => chain.traces).thenReturn([trace]);
      when(() => trace.frames).thenReturn([frame1, frame2]);
      when(() => frame1.package).thenReturn('excluded');
      when(() => frame2.package).thenReturn('excluded');
      expect(frameFromChain(chain, packageExcludeList: ['excluded']), frame1);
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
