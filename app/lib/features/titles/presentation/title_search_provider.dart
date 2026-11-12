import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/titles_repository.dart';
import '../domain/media_title.dart';

part 'title_search_provider.g.dart';

@Riverpod(retry: retryTransient)
Future<List<MediaTitle>> titleSearch(Ref ref, String query) async {
  final q = query.trim();
  // Same rule as the API DTO: a shorter query would get a 400.
  if (q.length < 2) return const [];

  // Watch before the debounce: this instance may be disposed once it ends.
  final repository = ref.watch(titlesRepositoryProvider);

  // Debounce: a new keystroke disposes this instance before the delay ends.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!ref.mounted) throw const SearchCancelled();

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return repository.search(q, cancelToken: cancelToken);
}

/// Thrown by an outdated search: never shown, and not retried since it isn't an ApiFailure.
class SearchCancelled implements Exception {
  const SearchCancelled();
}
