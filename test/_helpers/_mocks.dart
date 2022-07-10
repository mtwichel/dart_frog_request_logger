import 'dart:io';

import 'package:gcp_logger/gcp_logger.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:stack_trace/stack_trace.dart';

class MockFrame extends Mock implements Frame {}

class MockTrace extends Mock implements Trace {}

class MockChain extends Mock implements Chain {
  @override
  String toString() {
    return ' chain ';
  }
}

class MockPlatformWrapper extends Mock implements PlatformWrapper {}

class MockClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class MockUri extends Mock implements Uri {}

class MockShelfRequest extends Mock implements shelf.Request {}

class MockShelfResponse extends Mock implements shelf.Response {}

class MockStdout extends Mock implements Stdout {}
