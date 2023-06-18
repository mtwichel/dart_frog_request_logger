import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';

Response onRequest(RequestContext context) {
  context.read<RequestLogger>().debug('Hello Logs');
  return Response();
}
