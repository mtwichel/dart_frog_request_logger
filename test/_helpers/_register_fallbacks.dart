import 'package:mocktail/mocktail.dart';

class _MockUri extends Mock implements Uri {}

void registerFallbacks() {
  registerFallbackValue(_MockUri());
}
