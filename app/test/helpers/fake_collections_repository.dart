import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/collections/data/collections_repository.dart';
import 'package:filmo/features/collections/domain/collection_entry.dart';
import 'package:filmo/features/collections/domain/collection_members_entry.dart';

CollectionMembersEntry fakeMember({
  String id = 'user-1',
  String displayName = 'Léo',
  CollectionRole role = CollectionRole.owner,
}) => CollectionMembersEntry(
  role: role,
  joinedAt: DateTime(2026, 11, 26),
  user: MemberProfile(id: id, displayName: displayName),
);

CollectionEntry fakeCollection({
  String id = 'col-1',
  String name = 'Soirées',
  CollectionRole role = CollectionRole.owner,
}) => CollectionEntry(
  id: id,
  name: name,
  role: role,
  inviteCode: role == CollectionRole.owner ? 'ABCDEFGHJK' : null,
  itemCount: 2,
  memberCount: 3,
  createdAt: DateTime(2026, 11, 26),
);

/// In-memory fake; while [failure] is set, every call throws it.
class FakeCollectionsRepository implements CollectionsRepository {
  FakeCollectionsRepository([List<CollectionEntry>? initial])
    : stored = [...?initial];

  final List<CollectionEntry> stored;
  ApiFailure? failure;
  final joinedCodes = <String>[];
  List<CollectionMembersEntry> members = [
    fakeMember(),
    fakeMember(id: 'user-2', displayName: 'Sam', role: CollectionRole.member),
  ];

  void _maybeFail() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<List<CollectionEntry>> listMine() async {
    _maybeFail();
    return [...stored];
  }

  @override
  Future<CollectionEntry> create(String name) async {
    _maybeFail();
    final created = fakeCollection(id: 'new-${stored.length}', name: name);
    stored.add(created);
    return created;
  }

  @override
  Future<CollectionEntry> join(String inviteCode) async {
    joinedCodes.add(inviteCode);
    _maybeFail();
    final joined = fakeCollection(
      id: 'joined',
      name: 'Chez Sam',
      role: CollectionRole.member,
    );
    stored.add(joined);
    return joined;
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    stored.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> leave(String id) async {
    _maybeFail();
    stored.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<CollectionMembersEntry>> showMembers(String collectionId) async {
    _maybeFail();
    return [...members];
  }
}
