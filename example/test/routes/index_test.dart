import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequestLogger extends Mock implements RequestLogger {}

void main() {
  group('GET /', () {
    test('Logs the message', () {
      final context = _MockRequestContext();
      final logger = _MockRequestLogger();
      when(() => context.read<RequestLogger>()).thenReturn(logger);
      route.onRequest(context);

      verify(() => logger.debug('Hello Logs')).called(1);
    });
  });
}
