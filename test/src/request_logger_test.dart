import 'dart:io';

import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:dart_frog_request_logger/log_formatters.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

class MyObject {}

class _MockStdout extends Mock implements Stdout {}

class _MockChain extends Mock implements Chain {}

class _MockFrame extends Mock implements Frame {}

class _MockTrace extends Mock implements Trace {}

void main() {
  group('RequestLogger', () {
    group('log', () {
      test('writes log', () {
        final stdout = _MockStdout();
        RequestLogger(
          logFormatter: formatSimpleLog(),
          testingStdout: stdout,
          headers: {},
        ).log(Severity.info, 'message');
        verify(() => stdout.writeln(any())).called(1);
      });

      test('convenience methods call log', () {
        final stdout = _MockStdout();
        RequestLogger(
          logFormatter: formatSimpleLog(),
          testingStdout: stdout,
          headers: {},
        )
          ..alert('alert')
          ..critical('critical')
          ..debug('debug')
          ..emergency('emergency')
          ..error('error')
          ..info('info')
          ..normal('message')
          ..notice('notice')
          ..warning('warning');

        verify(() => stdout.writeln(any())).called(9);
      });

      test('fills in details if payload is not serializable', () {
        final stdout = _MockStdout();
        RequestLogger(
          logFormatter: formatSimpleLog(),
          testingStdout: stdout,
          headers: {},
        ).alert('alert', payload: MyObject());

        verify(() => stdout.writeln(any())).called(1);
      });
    });

    group('frameFromChain', () {
      test('returns null if chain is null or empty', () {
        expect(frameFromChain(null), null);
        final chain = _MockChain();
        when(() => chain.traces).thenReturn([]);
        expect(frameFromChain(chain), null);
      });

      test('returns null if first trace is empty', () {
        final chain = _MockChain();
        final trace = _MockTrace();
        when(() => chain.traces).thenReturn([trace]);
        when(() => trace.frames).thenReturn([]);
        expect(frameFromChain(chain), null);
      });

      test('returns first frame that is not excluded', () {
        final chain = _MockChain();
        final trace = _MockTrace();
        final frame1 = _MockFrame();
        final frame2 = _MockFrame();
        when(() => chain.traces).thenReturn([trace]);
        when(() => trace.frames).thenReturn([frame1, frame2]);
        when(() => frame1.package).thenReturn('excluded');
        when(() => frame2.package).thenReturn('included');
        expect(frameFromChain(chain, packageExcludeList: ['excluded']), frame2);
      });

      test('returns first frame that if all frames excluded', () {
        final chain = _MockChain();
        final trace = _MockTrace();
        final frame1 = _MockFrame();
        final frame2 = _MockFrame();
        when(() => chain.traces).thenReturn([trace]);
        when(() => trace.frames).thenReturn([frame1, frame2]);
        when(() => frame1.package).thenReturn('excluded');
        when(() => frame2.package).thenReturn('excluded');
        expect(frameFromChain(chain, packageExcludeList: ['excluded']), frame1);
      });
    });
  });
}
