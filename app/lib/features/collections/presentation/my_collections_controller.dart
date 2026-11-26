import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/collections_repository.dart';
import '../domain/collection_entry.dart';
import 'collection_validators.dart';

part 'my_collections_controller.g.dart';

// Mutations rethrow (shown by the caller) and leave the list untouched on failure.
@Riverpod(retry: retryTransient)
class MyCollectionsController extends _$MyCollectionsController {
  @override
  Future<List<CollectionEntry>> build() =>
      ref.watch(collectionsRepositoryProvider).listMine();

  Future<void> create(String name) async {
    final created = await ref
        .read(collectionsRepositoryProvider)
        .create(name.trim());
    _update((list) => [...list, created]);
  }

  Future<void> join(String inviteCode) async {
    final joined = await ref
        .read(collectionsRepositoryProvider)
        .join(CollectionValidators.normalizeInviteCode(inviteCode));
    _update((list) => [...list, joined]);
  }

  Future<void> delete(String id) async {
    await ref.read(collectionsRepositoryProvider).delete(id);
    _update((list) => list.where((c) => c.id != id).toList());
  }

  Future<void> leave(String id) async {
    await ref.read(collectionsRepositoryProvider).leave(id);
    _update((list) => list.where((c) => c.id != id).toList());
  }

  void _update(List<CollectionEntry> Function(List<CollectionEntry>) change) {
    // Disposed during the request (user left the screen): touching `state` would throw.
    if (!ref.mounted) return;
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
