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
  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (!ref.mounted) {
    throw Exception('Search cancelled');
  }
  if (!ref.mounted && ref.isReload) {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    return ref
        .watch(titlesRepositoryProvider)
        .search(q, cancelToken: cancelToken);
  }
  return ref.watch(titlesRepositoryProvider).search(q);
}
