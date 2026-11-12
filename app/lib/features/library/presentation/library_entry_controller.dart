import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../../titles/domain/media_title.dart';
import '../data/library_repository.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

part 'library_entry_controller.g.dart';

/// State of ONE title in my library, for the detail screen. This is the "ViewModel":
/// the screen reads `state` and calls methods, it never talks to the repository.
///
/// `AsyncData(null)` = not in my library yet.
/// Family on titleId (the build parameter): each detail screen gets its own instance.
@Riverpod(retry: retryTransient)
class LibraryEntryController extends _$LibraryEntryController {
  /// True while a PUT/DELETE is in flight. Plain field (not state): the UI doesn't need to rebuild for it.
  bool _saving = false;

  @override
  Future<LibraryEntry?> build(String titleId) =>
      ref.watch(libraryRepositoryProvider).find(titleId);

  /// Keeps the current rating: changing "En cours" → "Vu" must not erase the 8/10.
  /// [title] builds the optimistic entry when the title isn't in the library yet.
  Future<void> setStatus(WatchStatus status, {required MediaTitle title}) =>
      _save(status: status, rating: state.value?.rating, title: title);

  /// Rating needs a status (the API requires one), so it only works once the title is in the library.
  Future<void> setRating(int? rating) async {
    final current = state.value;
    if (current == null) return;
    await _save(status: current.status, rating: rating, title: current.title);
  }

  Future<void> remove() => _exclusive(() async {
    await ref.read(libraryRepositoryProvider).remove(titleId);
    if (!ref.mounted) return;
    state = const AsyncData(null);
  });

  // Errors are rethrown to the screen (which shows a SnackBar) instead of being put in `state`:
  // an AsyncError would replace the whole section with an error message for a simple failed click.
  // Same choice as AuthController.
  Future<void> _save({
    required WatchStatus status,
    required MediaTitle title,
    int? rating,
  }) => _exclusive(() async {
    // Optimistic update: show the expected result before the server answers, roll back on failure.
    final previous = state;
    final current = state.value;
    state = AsyncData(
      current == null
          ? LibraryEntry(
              titleId: titleId,
              status: status,
              rating: rating,
              title: title,
            )
          : current.copyWith(status: status, rating: rating),
    );

    try {
      final saved = await ref
          .read(libraryRepositoryProvider)
          .save(titleId, status: status, rating: rating);
      // Disposed during the request (user left the screen): touching `state` would throw.
      if (!ref.mounted) return;
      // The server's answer wins: it carries watchedAt, which we can't guess.
      state = AsyncData(saved);
    } catch (_) {
      // No `return` here: rethrow so the screen shows the SnackBar.
      // Rolling back to `previous` is safe only because _exclusive forbids concurrent saves.
      if (ref.mounted) state = previous;
      rethrow;
    }
  });

  /// One mutation at a time. Without this, tapping "Vu" then changing the rating before the
  /// first answer would send 2 PUTs built from stale state (PUT replaces everything: lost update),
  /// and their answers could come back in any order. A tap during a save is simply ignored.
  Future<void> _exclusive(Future<void> Function() mutation) async {
    if (_saving) return;
    _saving = true;
    try {
      await mutation();
    } finally {
      _saving = false;
    }
  }
}
