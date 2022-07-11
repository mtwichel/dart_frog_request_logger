import 'dart:io';

import 'package:request_logger/log_formatters.dart';
import 'package:request_logger/request_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/error', _errorHandler);

Response _rootHandler(Request request) {
  final logger = RequestLogger.extractLogger(request);
  logger.debug('Hello Logs');
  return Response.ok('Hello, World!\n');
}

Response _errorHandler(Request request) {
  throw Exception('This endpoint is designed to fail.');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests with RequestLogger.
  final handler = Pipeline()
      .addMiddleware(RequestLogger.middleware(logFormatter: formatSimpleLog()))
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
