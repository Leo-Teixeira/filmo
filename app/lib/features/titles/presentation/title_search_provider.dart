import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/titles_repository.dart';
import '../domain/media_title.dart';

part 'title_search_provider.g.dart';

/// Search results for one query. A function parameter = a "family": each
/// distinct query string gets its own provider instance (and its own cache).
///
/// Auto-dispose (because keepAlive defaults to false): when the screen stops
/// watching "dun", that instance is destroyed. That's what makes défi 2 possible.
@Riverpod(retry: retryTransient)
Future<List<MediaTitle>> titleSearch(Ref ref, String query) async {
  final q = query.trim();
  // Same rule as the API DTO (Length 2..100): don't even send a request that would get a 400.
  if (q.length < 2) return const [];

  // Read dependencies before any await: Riverpod tracks them from the start of build.
  final repository = ref.watch(titlesRepositoryProvider);

  // Debounce: each keystroke creates a new family instance and disposes the previous
  // one. Only the instance that survives 350 ms of silence reaches the API.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!ref.mounted) throw const SearchCancelled();

  // Cancel: if the user types again while the request is in flight, this instance
  // gets disposed and the HTTP request is aborted instead of finishing for nothing.
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return repository.search(q, cancelToken: cancelToken);
}

/// Thrown by an outdated search. Nobody listens to that instance anymore, so it's never
/// shown; it's not an ApiFailure, so retryTransient doesn't retry it.
class SearchCancelled implements Exception {
  const SearchCancelled();
}
