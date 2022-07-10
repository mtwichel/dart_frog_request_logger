import 'package:dart_frog/dart_frog.dart';
import 'package:gcp_logger/gcp_logger.dart';

Handler middleware(Handler handler) {
  return handler.use(fromShelfMiddleware(GcpLogger.middleware()));
}
