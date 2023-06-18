import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

export '_register_fallbacks.dart';

dynamic expectJson(String actual, Map<String, dynamic> json) =>
    expect(jsonDecode(actual), json);

extension ReturnAsync<T> on When<Future<T>> {
  void thenReturnAsync(T expected) {
    thenAnswer((_) async => expected);
  }
}
