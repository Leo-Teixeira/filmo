import 'dart:async';

import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/library/data/library_repository.dart';
import 'package:filmo/features/library/domain/library_entry.dart';
import 'package:filmo/features/library/domain/watch_status.dart';
import 'package:filmo/features/library/presentation/library_entry_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_library_repository.dart';

const _titleId = 'dune-uuid';

void main() {
  late FakeLibraryRepository repo;
  late ProviderContainer container;

  // Shortcuts for the family instance under test.
  final provider = libraryEntryControllerProvider(_titleId);
  LibraryEntryController controller() => container.read(provider.notifier);
  LibraryEntry? current() => container.read(provider).value;

  setUp(() async {
    repo = FakeLibraryRepository();
    // ProviderContainer.test disposes itself at the end of the test.
    container = ProviderContainer.test(
      overrides: [libraryRepositoryProvider.overrideWithValue(repo)],
    );
    // Auto-dispose provider: without a listener it would be destroyed between two reads.
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
  });

  test('starts as "not in my library"', () {
    expect(current(), isNull);
  });

  test(
    'setStatus adds the title and keeps the rating on later changes',
    () async {
      await controller().setStatus(WatchStatus.watching, title: fakeTitle);
      await controller().setRating(8);
      await controller().setStatus(WatchStatus.completed, title: fakeTitle);

      expect(current()?.status, WatchStatus.completed);
      expect(current()?.rating, 8);
    },
  );

  test('remove goes back to null', () async {
    await controller().setStatus(WatchStatus.watching, title: fakeTitle);
    await controller().remove();

    expect(current(), isNull);
  });

  test('ignores a second save while one is in flight (no lost update)', () async {
    repo.pending = Completer<void>();

    final first = controller().setStatus(
      WatchStatus.watching,
      title: fakeTitle,
    );
    // Server hasn't answered yet: this one must be dropped, not sent with stale data.
    await controller().setStatus(WatchStatus.dropped, title: fakeTitle);
    repo.pending!.complete();
    await first;

    expect(repo.saves, 1);
    expect(current()?.status, WatchStatus.watching);
  });

  test('a failed save is rethrown and leaves the state untouched', () async {
    await controller().setStatus(WatchStatus.watching, title: fakeTitle);
    repo.failure = const ApiOffline();

    await expectLater(
      controller().setStatus(WatchStatus.dropped, title: fakeTitle),
      throwsA(isA<ApiOffline>()),
    );
    expect(current()?.status, WatchStatus.watching);
  });

  test(
    'updates the state before the server answers (optimistic)',
    () async {
      await controller().setStatus(WatchStatus.watching, title: fakeTitle);
      repo.pending = Completer<void>();

      final saving = controller().setStatus(
        WatchStatus.completed,
        title: fakeTitle,
      );
      // Server hasn't answered yet, but the UI should already show "Vu".
      expect(current()?.status, WatchStatus.completed);

      repo.pending!.complete();
      await saving;
    },
    // TODO(Léo) — DÉFI 3 : enlève `skip: true` quand _save() est optimiste.
    skip: true,
  );
}
