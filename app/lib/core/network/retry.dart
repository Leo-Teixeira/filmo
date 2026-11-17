import 'api_failure.dart';

/// Riverpod 3 retries any failing provider up to 10 times: only retry transient errors, twice.
Duration? retryTransient(int retryCount, Object error) {
  if (error is! ApiFailure || !error.isTransient) return null;
  if (retryCount >= 2) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}
