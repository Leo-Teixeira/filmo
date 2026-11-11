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
  ///
  /// [title] is not used yet: défi 3 needs it to build an optimistic entry when the
  /// title isn't in the library (state is null). Passed by the screen, which already has it.
  Future<void> setStatus(WatchStatus status, {required MediaTitle title}) =>
      _save(status: status, rating: state.value?.rating);

  /// Rating needs a status (the API requires one), so it only works once the title is in the library.
  Future<void> setRating(int? rating) async {
    final current = state.value;
    if (current == null) return;
    await _save(status: current.status, rating: rating);
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
    int? rating,
  }) => _exclusive(() async {
    final previous = state;
    state = AsyncData(state.value?.copyWith(status: status, rating: rating));
    // TODO(Léo) — DÉFI 3 : mise à jour optimiste + rollback.
    // Aujourd'hui l'UI attend la réponse du serveur (~200 ms) avant de bouger : ça "lag".
    // À faire :
    //   1. Garder l'état actuel : `final previous = state;`
    //   2. Mettre à jour `state` TOUT DE SUITE (avant le premier await) avec la valeur attendue :
    //        - entrée existante → AsyncData(current.copyWith(status: status, rating: rating))
    //        - pas encore d'entrée (null) → construire un LibraryEntry avec le `title` reçu
    //          par setStatus (fais-le descendre jusqu'ici en paramètre).
    //   3. Appeler l'API. Succès → `if (!ref.mounted) return; state = AsyncData(saved);`
    //      (la réponse serveur fait foi : elle contient watchedAt).
    //   4. Échec → `catch (_) { if (ref.mounted) state = previous; rethrow; }`
    //      Attention : un simple `if (!ref.mounted) return;` dans le catch avalerait l'erreur.
    //   5. Le rollback vers `previous` est sûr uniquement parce que _exclusive empêche
    //      deux sauvegardes en parallèle. Question : que se passerait-il sans ce verrou ?
    //   6. Enlève le `skip:` du test « updates the state before the server answers ».
    final saved = await ref
        .read(libraryRepositoryProvider)
        .save(titleId, status: status, rating: rating);
    // The user may have left the screen during the request: the instance is then disposed
    // and touching `state` would throw in Riverpod 3.
    if (!ref.mounted) return;
    state = AsyncData(saved);
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
