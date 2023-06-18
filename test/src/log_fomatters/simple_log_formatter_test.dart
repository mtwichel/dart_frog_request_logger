import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:dart_frog_request_logger/log_formatters.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockFrame extends Mock implements Frame {}

class _MockChain extends Mock implements Chain {
  @override
  String toString() {
    return 'chain';
  }
}

void main() {
  group('formatSimpleLog()', () {
    test('returns base log correctly', () {
      expect(
        formatSimpleLog()(
          severity: Severity.alert,
          message: 'message',
          headers: {},
        ),
        '[ALERT] message\n',
      );
    });

    test('returns log with stack frame correctly', () {
      final stackFrame = _MockFrame();
      when(() => stackFrame.library).thenReturn('file');
      when(() => stackFrame.line).thenReturn(1);
      when(() => stackFrame.column).thenReturn(1);
      when(() => stackFrame.member).thenReturn('function');

      expect(
        formatSimpleLog()(
          severity: Severity.alert,
          message: 'message',
          headers: {},
          stackFrame: stackFrame,
        ),
        '[ALERT] message\n'
        '  file:1:1 (function)\n',
      );
    });

    test('returns log with labels correctly', () {
      expect(
        formatSimpleLog()(
          severity: Severity.alert,
          message: 'message',
          headers: {},
          labels: {'test': 'test'},
        ),
        '[ALERT] message\n'
        '  Labels: {"test":"test"}\n',
      );
    });

    test('returns log with payload correctly', () {
      expect(
        formatSimpleLog()(
          severity: Severity.alert,
          message: 'message',
          headers: {},
          payload: {'test': 'test'},
        ),
        '[ALERT] message\n'
        '  Payload: {"test":"test"}\n',
      );
    });
    test('returns log with chain correctly', () {
      final chain = _MockChain();
      expect(
        formatSimpleLog()(
          severity: Severity.alert,
          message: 'message',
          headers: {},
          chain: chain,
        ),
        '[ALERT] message\n'
        'chain\n',
      );
    });
  });
}
