import 'dart:io';

import 'package:gcp_logger/gcp_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../_helpers/_helpers.dart';

void main() {
  setUpAll(registerFallbacks);
  group('currentProjectId', () {
    test('runs without dependencies injected', () async {
      expect(
        () async => currentProjectId(),
        throwsException,
      );
    });
    test('returns projectId if set in environment variable', () async {
      final platformWrapper = MockPlatformWrapper();
      when(() => platformWrapper.environment).thenReturn(
        {
          'GCP_PROJECT': 'projectId',
        },
      );

      expect(
        await currentProjectId(
          platformWrapper: platformWrapper,
        ),
        'projectId',
      );
    });

    test('returns the project id if http request is successful', () async {
      final platformWrapper = MockPlatformWrapper();
      final client = MockClient();
      final response = MockResponse();

      when(() => platformWrapper.environment).thenReturn({});
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenReturnAsync(response);
      when(() => response.statusCode).thenReturn(200);
      when(() => response.body).thenReturn('projectId');

      expect(
        await currentProjectId(
          platformWrapper: platformWrapper,
          httpClient: client,
        ),
        'projectId',
      );
    });

    test('throws an HttpException if http request fails', () async {
      final platformWrapper = MockPlatformWrapper();
      final client = MockClient();
      final response = MockResponse();

      when(() => platformWrapper.environment).thenReturn({});
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenReturnAsync(response);
      when(() => response.statusCode).thenReturn(500);
      when(() => response.body).thenReturn('oops');

      expect(
        () async => currentProjectId(
          platformWrapper: platformWrapper,
          httpClient: client,
        ),
        throwsA(isA<HttpException>()),
      );
    });

    test('thows a NoProjectIdFoundException if no project id was found',
        () async {
      final platformWrapper = MockPlatformWrapper();
      final client = MockClient();

      when(() => platformWrapper.environment).thenReturn({});
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('oops'));
      expect(
        () async => currentProjectId(
          platformWrapper: platformWrapper,
          httpClient: client,
        ),
        throwsA(isA<NoProjectIdFoundException>()),
      );
    });
  });
  group('NoProjectIdFoundException', () {
    test('message returns correctly', () {
      expect(
        NoProjectIdFoundException().message,
        'Could not connect to http://metadata.google.internal/. If not running on Google Cloud, '
        'one of these environment variables must be set '
        'to the target Google Project ID: '
        'GCP_PROJECT, GCLOUD_PROJECT, CLOUDSDK_CORE_PROJECT, '
        'GOOGLE_CLOUD_PROJECT',
      );
    });
  });

  group('PlatformWrapper', () {
    test('environment returns environemnt variables', () {
      expect(PlatformWrapper().environment, Platform.environment);
    });
  });
}
