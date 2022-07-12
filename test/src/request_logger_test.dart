// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:request_logger/log_formatters.dart';
import 'package:request_logger/request_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../_helpers/_helpers.dart';

void main() {
  group('RequestLogger', () {
    final request = MockShelfRequest();
    group('log', () {
      test('writes log', () {
        final stdout = MockStdout();
        RequestLogger(
          logFormatter: formatSimpleLog(),
          testingStdout: stdout,
          request: request,
        ).log(Severity.info, 'message');
        verify(() => stdout.writeln(any())).called(1);
      });

      test('convenience methods call log', () {
        final stdout = MockStdout();
        RequestLogger(
          logFormatter: formatSimpleLog(),
          testingStdout: stdout,
          request: request,
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
    });

    group('middleware', () {
      String testingLogFormatter({
        Chain? chain,
        bool? isError,
        Map<String, dynamic>? labels,
        required String message,
        Map<String, dynamic>? payload,
        required Severity severity,
        Frame? stackFrame,
        required Request request,
      }) =>
          'log';

      late Request request;
      late Response response;

      setUp(() {
        request = MockShelfRequest();
        response = MockShelfResponse();
        when(() => request.change(context: any(named: 'context')))
            .thenReturn(request);
        when(() => request.method).thenReturn('GET');
        when(() => request.handlerPath).thenReturn('/');
        when(() => request.headers)
            .thenReturn({'X-Cloud-Trace-Context': 'trace'});

        when(() => response.statusCode).thenReturn(200);
      });

      test('logs uncaught errors automatically', () async {
        final stdout = MockStdout();

        final middleware = RequestLogger.middleware(
          testingStdout: stdout,
          logFormatter: testingLogFormatter,
        );
        final newHandler = middleware(
          (request) {
            throw Error();
          },
        );
        final newResponse = await newHandler(request);
        verify(() => stdout.writeln(any())).called(1);
        expect(newResponse.statusCode, HttpStatus.internalServerError);
        expect(await newResponse.readAsString(), 'Internal Server Error');
      });

      test('rethrows HijackExceptions', () async {
        final middleware = RequestLogger.middleware(
          logFormatter: formatSimpleLog(),
        );
        final newHandler = middleware(
          (request) {
            throw const HijackException();
          },
        );
        expect(
          () async => newHandler(request),
          throwsA(isA<HijackException>()),
        );
      });

      test('injects a RequestLogger into the Request context', () async {
        final modifiedRequest = MockShelfRequest();
        when(() => modifiedRequest.method).thenReturn('GET');

        final middleware = RequestLogger.middleware(
          logFormatter: testingLogFormatter,
        );
        final newHandler = middleware((request) => response);
        await newHandler(request);

        verify(
          () => request.change(
            context: any(
              named: 'context',
              that: isA<Map<String, dynamic>>().having(
                (m) => m['RequestLogger'],
                'logger',
                isA<Function>().having(
                  // ignore: avoid_dynamic_calls
                  (f) => f.call(),
                  'returns',
                  isA<RequestLogger>(),
                ),
              ),
            ),
          ),
        ).called(1);
      });

      test('logs requests if parameter passed and no error occur', () async {
        final stdout = MockStdout();

        final middleware = RequestLogger.middleware(
          testingStdout: stdout,
          shouldLogRequests: true,
          logFormatter: testingLogFormatter,
        );
        final newHandler = middleware((request) => response);
        await newHandler(request);
        verify(() => stdout.writeln(any())).called(1);
      });
      test('logs requests if parameter passed and an error occurs', () async {
        final stdout = MockStdout();

        final middleware = RequestLogger.middleware(
          testingStdout: stdout,
          shouldLogRequests: true,
          logFormatter: testingLogFormatter,
        );
        final newHandler = middleware((request) => throw Error());
        await newHandler(request);
        verify(() => stdout.writeln(any())).called(2);
      });
    });

    group('extractLogger', () {
      test('returns logger', () {
        final request = MockShelfRequest();
        final logger = RequestLogger(
          logFormatter: formatSimpleLog(),
          request: request,
        );
        when(() => request.context).thenReturn(
          {'RequestLogger': () => logger},
        );
        expect(
          RequestLogger.extractLogger(request),
          logger,
        );
      });
      test('throws StateError if logger not injected', () {
        final request = MockShelfRequest();
        when(() => request.context).thenReturn({});
        expect(
          () => RequestLogger.extractLogger(request),
          throwsA(isA<StateError>()),
        );
      });
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
}
