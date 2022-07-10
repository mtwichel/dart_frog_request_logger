import 'package:gcp_logger/gcp_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../_helpers/_helpers.dart';

void main() {
  group('formatSimpleLog', () {
    test('returns base log correctly', () {
      expect(
        formatSimpleLog(severity: Severity.alert, message: 'message'),
        '[ALERT] message',
      );
    });

    test('returns log with stack frame correctly', () {
      final stackFrame = MockFrame();
      when(() => stackFrame.library).thenReturn('file');
      when(() => stackFrame.line).thenReturn(1);
      when(() => stackFrame.column).thenReturn(1);
      when(() => stackFrame.member).thenReturn('function');

      expect(
        formatSimpleLog(
          severity: Severity.alert,
          message: 'message',
          stackFrame: stackFrame,
        ),
        '[ALERT] message\n'
        '  file:1:1 (function)',
      );
    });

    test('returns log with labels correctly', () {
      expect(
        formatSimpleLog(
          severity: Severity.alert,
          message: 'message',
          labels: {'test': 'test'},
        ),
        '[ALERT] message\n'
        '  Labels: {"test":"test"}',
      );
    });

    test('returns log with payload correctly', () {
      expect(
        formatSimpleLog(
          severity: Severity.alert,
          message: 'message',
          payload: {'test': 'test'},
        ),
        '[ALERT] message\n'
        '  Payload: {"test":"test"}',
      );
    });
    test('returns log with chain correctly', () {
      final chain = MockChain();
      expect(
        formatSimpleLog(
          severity: Severity.alert,
          message: 'message',
          chain: chain,
        ),
        '[ALERT] message\n'
        'chain',
      );
    });
  });
}
