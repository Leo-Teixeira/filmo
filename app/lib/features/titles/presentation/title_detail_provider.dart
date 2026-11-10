import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/titles_repository.dart';
import '../domain/media_title.dart';

part 'title_detail_provider.g.dart';

/// One title by our uuid. Family on `id`: opening Dune then Matrix = 2 independent
/// instances, and coming back to Dune while it's still watched doesn't refetch.
@Riverpod(retry: retryTransient)
Future<MediaTitle> titleDetail(Ref ref, String id) =>
    ref.watch(titlesRepositoryProvider).getById(id);
