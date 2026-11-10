import 'api_failure.dart';

/// Retry policy for providers that call the API, passed as `@Riverpod(retry: retryTransient)`.
///
/// Riverpod 3 retries every failing provider by default (up to 10 times, with
/// backoff). Fine for a flaky network, absurd for a 404: it would hit the API
/// 10 times for a title that doesn't exist. So: transient errors only, 2 tries max.
/// Returning null = "stop retrying, keep the error".
Duration? retryTransient(int retryCount, Object error) {
  if (error is! ApiFailure || !error.isTransient) return null;
  if (retryCount >= 2) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}
