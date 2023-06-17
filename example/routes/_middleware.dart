import 'package:dart_frog/dart_frog.dart';
import 'package:request_logger/log_formatters.dart';
import 'package:request_logger/request_logger.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<RequestLogger>(
      (context) => RequestLogger(
        headers: context.request.headers,
        logFormatter: formatSimpleLog(),
      ),
    ),
  );
}
