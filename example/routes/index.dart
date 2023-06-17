import 'package:dart_frog/dart_frog.dart';
import 'package:request_logger/request_logger.dart';

Response onRequest(RequestContext context) {
  context.read<RequestLogger>().debug('Hello Logs');
  return Response();
}
