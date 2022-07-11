// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:gcp_logger/gcp_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import '../_helpers/_helpers.dart';

void main() {
  group('GcpLogger', () {
    group('log', () {
      test('writes log', () {
        final stdout = MockStdout();
        GcpLogger(
          logFormatter: formatSimpleLog,
          testingStdout: stdout,
        ).log(Severity.info, 'message');
        verify(() => stdout.writeln(any())).called(1);
      });

      test('convenience methods call log', () {
        final stdout = MockStdout();
        GcpLogger(
          logFormatter: formatSimpleLog,
          testingStdout: stdout,
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
        String? projectId,
        required Severity severity,
        Frame? stackFrame,
        String? trace,
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

      test('creates new logger if running on gcp', () async {
        final stdout = MockStdout();

        final middleware = GcpLogger.middleware(
          testingStdout: stdout,
          projectIdGetter: () async => 'projectId',
        );
        final newHandler = middleware(
          (request) => response,
        );
        await newHandler(request);

        verifyNever(() => stdout.writeln());
      });

      test('logs uncaught errors automatically', () async {
        final stdout = MockStdout();

        final middleware = GcpLogger.middleware(
          testingStdout: stdout,
          projectIdGetter: () async => 'projectId',
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
        final middleware = GcpLogger.middleware();
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

      test('injects a GcpLogger into the Request context', () async {
        final modifiedRequest = MockShelfRequest();
        when(() => modifiedRequest.method).thenReturn('GET');

        final middleware = GcpLogger.middleware(
          projectIdGetter: () async => 'projectId',
          logFormatter: testingLogFormatter,
        );
        final newHandler = middleware((request) => response);
        await newHandler(request);

        verify(
          () => request.change(
            context: any(
              named: 'context',
              that: isA<Map<String, dynamic>>().having(
                (m) => m['GcpLogger'],
                'logger',
                isA<Function>().having(
                  // ignore: avoid_dynamic_calls
                  (f) => f.call(),
                  'returns',
                  isA<GcpLogger>(),
                ),
              ),
            ),
          ),
        ).called(1);
      });

      test('logs requests if parameter passed and no error occur', () async {
        final stdout = MockStdout();

        final middleware = GcpLogger.middleware(
          testingStdout: stdout,
          shouldLogRequests: true,
          logFormatter: testingLogFormatter,
          projectIdGetter: () async => 'projectId',
        );
        final newHandler = middleware((request) => response);
        await newHandler(request);
        verify(() => stdout.writeln(any())).called(1);
      });
      test('logs requests if parameter passed and an error occurs', () async {
        final stdout = MockStdout();

        final middleware = GcpLogger.middleware(
          testingStdout: stdout,
          shouldLogRequests: true,
          logFormatter: testingLogFormatter,
          projectIdGetter: () async => 'projectId',
        );
        final newHandler = middleware((request) => throw Error());
        await newHandler(request);
        verify(() => stdout.writeln(any())).called(2);
      });
    });

    group('extractLogger', () {
      test('returns logger', () {
        final request = MockShelfRequest();
        const logger = GcpLogger(logFormatter: formatSimpleLog);
        when(() => request.context).thenReturn(
          {'GcpLogger': () => logger},
        );
        expect(
          GcpLogger.extractLogger(request),
          logger,
        );
      });
      test('throws StateError if logger not injected', () {
        final request = MockShelfRequest();
        when(() => request.context).thenReturn({});
        expect(
          () => GcpLogger.extractLogger(request),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
