import 'package:dart_frog/dart_frog.dart';
import 'package:gcp_logger/gcp_logger.dart';

Response onRequest(RequestContext context) {
  context.read<GcpLogger>().debug('Hello Logs');
  return Response();
}
