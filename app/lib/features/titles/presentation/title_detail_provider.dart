import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/titles_repository.dart';
import '../domain/media_title.dart';

part 'title_detail_provider.g.dart';

@Riverpod(retry: retryTransient)
Future<MediaTitle> titleDetail(Ref ref, String id) =>
    ref.watch(titlesRepositoryProvider).getById(id);
