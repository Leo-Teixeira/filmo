import 'package:filmo/core/network/retry.dart';
import 'package:filmo/features/collections/data/collections_repository.dart';
import 'package:filmo/features/collections/domain/collection_members_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collection_members_controller.g.dart';

@Riverpod(retry: retryTransient)
class CollectionMembersController extends _$CollectionMembersController {
  @override
  Future<List<CollectionMembersEntry>> build(String id) async {
    return ref.watch(collectionsRepositoryProvider).showMembers(id);
  }
}
