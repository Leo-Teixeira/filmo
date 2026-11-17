import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../../titles/domain/media_title.dart';
import '../data/library_repository.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

part 'library_entry_controller.g.dart';

/// `AsyncData(null)` = not in my library yet.
@Riverpod(retry: retryTransient)
class LibraryEntryController extends _$LibraryEntryController {
  bool _saving = false;

  @override
  Future<LibraryEntry?> build(String titleId) =>
      ref.watch(libraryRepositoryProvider).find(titleId);

  /// Keeps the current rating; [title] builds the entry on a first optimistic add.
  Future<void> setStatus(WatchStatus status, {required MediaTitle title}) =>
      _save(status: status, rating: state.value?.rating, title: title);

  /// Only once the title is in the library: the API requires a status with a rating.
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

  // Errors are rethrown (SnackBar), not stored: a failed tap must not wipe the section.
  Future<void> _save({
    required WatchStatus status,
    required MediaTitle title,
    int? rating,
  }) => _exclusive(() async {
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
      // Rolling back to `previous` is safe only because _exclusive forbids concurrent saves.
      if (ref.mounted) state = previous;
      rethrow;
    }
  });

  /// One mutation at a time; taps during a save are dropped, not queued (stale PUTs lose updates).
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
