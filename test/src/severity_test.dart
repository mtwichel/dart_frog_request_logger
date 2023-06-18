import 'package:dart_frog_request_logger/dart_frog_request_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Severity', () {
    test('toString returns correctly', () {
      expect(Severity.alert.toString(), 'ALERT');
      expect(Severity.critical.toString(), 'CRITICAL');
      expect(Severity.debug.toString(), 'DEBUG');
      expect(Severity.emergency.toString(), 'EMERGENCY');
      expect(Severity.error.toString(), 'ERROR');
      expect(Severity.normal.toString(), 'DEFAULT');
      expect(Severity.info.toString(), 'INFO');
      expect(Severity.notice.toString(), 'NOTICE');
    });
  });
}
