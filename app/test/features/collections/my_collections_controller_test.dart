import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/collections/data/collections_repository.dart';
import 'package:filmo/features/collections/domain/collection_entry.dart';
import 'package:filmo/features/collections/presentation/my_collections_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_collections_repository.dart';

void main() {
  late FakeCollectionsRepository repo;
  late ProviderContainer container;

  MyCollectionsController controller() =>
      container.read(myCollectionsControllerProvider.notifier);
  List<CollectionEntry>? current() =>
      container.read(myCollectionsControllerProvider).value;

  setUp(() async {
    repo = FakeCollectionsRepository([fakeCollection()]);
    container = ProviderContainer.test(
      overrides: [collectionsRepositoryProvider.overrideWithValue(repo)],
    );
    container.listen(myCollectionsControllerProvider, (_, _) {});
    await container.read(myCollectionsControllerProvider.future);
  });

  test('loads my collections', () {
    expect(current()?.map((c) => c.id), ['col-1']);
  });

  test('create trims the name and appends the collection', () async {
    await controller().create('  Films  ');

    expect(current()?.last.name, 'Films');
  });

  test('join normalizes the code and appends the collection', () async {
    await controller().join(' abcdefghjk ');

    expect(repo.joinedCodes, ['ABCDEFGHJK']);
    expect(current()?.last.role, CollectionRole.member);
  });

  test('delete and leave remove the collection from the list', () async {
    await controller().join('ABCDEFGHJK');
    await controller().delete('col-1');
    await controller().leave('joined');

    expect(current(), isEmpty);
  });

  test('a failed mutation rethrows and keeps the list', () async {
    repo.failure = const ApiConflict();

    await expectLater(
      controller().join('ABCDEFGHJK'),
      throwsA(isA<ApiConflict>()),
    );
    expect(current()?.map((c) => c.id), ['col-1']);
  });
}
