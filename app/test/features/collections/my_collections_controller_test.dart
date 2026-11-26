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

  Future<void> start(FakeCollectionsRepository fake) async {
    repo = fake;
    container = ProviderContainer.test(
      overrides: [collectionsRepositoryProvider.overrideWithValue(repo)],
    );
    container.listen(myCollectionsControllerProvider, (_, _) {});
    await container
        .read(myCollectionsControllerProvider.future)
        .catchError((_) => <CollectionEntry>[]);
  }

  setUp(() => start(FakeCollectionsRepository([fakeCollection()])));

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

  test('delete removes the collection from the list', () async {
    await controller().delete('col-1');

    expect(current(), isEmpty);
  });

  test('leave removes the collection from the list', () async {
    await controller().join('ABCDEFGHJK');
    await controller().leave('joined');

    expect(current()?.map((c) => c.id), ['col-1']);
  });

  test('a failed mutation rethrows and keeps the list', () async {
    repo.failure = const ApiConflict();

    await expectLater(
      controller().join('ABCDEFGHJK'),
      throwsA(isA<ApiConflict>()),
    );
    expect(current()?.map((c) => c.id), ['col-1']);
  });

  test('a mutation after a failed load reloads the list', () async {
    // Non-transient on purpose: a retry must not be what reloads the list.
    final fake = FakeCollectionsRepository()..failure = const ApiNotFound();
    await start(fake);
    expect(container.read(myCollectionsControllerProvider).hasError, isTrue);

    fake.failure = null;
    await controller().create('Films');
    final reloaded = await container.read(
      myCollectionsControllerProvider.future,
    );

    expect(reloaded.map((c) => c.name), ['Films']);
  });
}
