import 'package:filmo/features/collections/domain/collection_members_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/collections_repository.dart';
import '../domain/collection_entry.dart';
import 'collection_validators.dart';

part 'my_collections_controller.g.dart';

// Mutations rethrow (shown by the caller) and leave the list untouched on failure.
@Riverpod(retry: retryTransient)
class MyCollectionsController extends _$MyCollectionsController {
  final _removing = <String>{};

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

  Future<void> delete(String id) =>
      _remove(id, ref.read(collectionsRepositoryProvider).delete);

  Future<void> leave(String id) =>
      _remove(id, ref.read(collectionsRepositoryProvider).leave);

  /// A second tap while the request is in flight is dropped, not sent twice.
  Future<void> _remove(String id, Future<void> Function(String) request) async {
    if (!_removing.add(id)) return;
    try {
      await request(id);
      _update((list) => list.where((c) => c.id != id).toList());
    } finally {
      _removing.remove(id);
    }
  }

  Future<List<CollectionMembersEntry>> showMembers(String id) async {
    return ref.watch(collectionsRepositoryProvider).showMembers(id);
  }

  void _update(List<CollectionEntry> Function(List<CollectionEntry>) change) {
    // Disposed during the request (user left the screen): touching `state` would throw.
    if (!ref.mounted) return;
    final current = state.value;
    // No list yet (loading or failed): reload so the server-side change shows up.
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(
      change(current)..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
  }
}
