import 'dart:io';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// Returns the id of the GCP project this is running on
/// If not project id is found, it thows a
Future<String> currentProjectId({
  @visibleForTesting Client? httpClient,
  @visibleForTesting PlatformWrapper? platformWrapper,
}) async {
  final _platformWrapper = platformWrapper ?? PlatformWrapper();
  final _httpClient = httpClient ?? Client();

  for (final envKey in _gcpProjectIdEnvironmentVariables) {
    final value = _platformWrapper.environment[envKey];
    if (value != null) return value;
  }

  try {
    final response = await _httpClient.get(
      _url,
      headers: {'Metadata-Flavor': 'Google'},
    );

    if (response.statusCode != 200) {
      throw HttpException(
        '${response.body} (${response.statusCode})',
        uri: _url,
      );
    }

    return response.body;
  } on SocketException {
    throw NoProjectIdFoundException();
  }
}

/// A set of typical environment variables that are likely to represent the
/// current Google Cloud project ID.
///
/// For context, see:
/// * https://cloud.google.com/functions/docs/env-var
/// * https://cloud.google.com/compute/docs/gcloud-compute#default_project
/// * https://github.com/GoogleContainerTools/gcp-auth-webhook/blob/08136ca171fe5713cc70ef822c911fbd3a1707f5/server.go#L38-L44
///
/// Note: these are ordered starting from the most current/canonical to least.
/// (At least as could be determined at the time of writing.)
const _gcpProjectIdEnvironmentVariables = {
  'GCP_PROJECT',
  'GCLOUD_PROJECT',
  'CLOUDSDK_CORE_PROJECT',
  'GOOGLE_CLOUD_PROJECT',
};

const _host = 'http://metadata.google.internal/';
final _url = Uri.parse('$_host/computeMetadata/v1/project/project-id');

/// Thrown if no project id is detected when running [currentProjectId]
class NoProjectIdFoundException implements Exception {
  /// The message to display if this exception is thrown.
  String get message =>
      'Could not connect to $_host. If not running on Google Cloud, '
      'one of these environment variables must be set '
      'to the target Google Project ID: '
      '${_gcpProjectIdEnvironmentVariables.join(', ')}';
}

/// A wrapper around [Platform] so that it can be injected and tested
class PlatformWrapper {
  /// The environment for this process as a map from string key to string value.
  Map<String, String> get environment => Platform.environment;
}
