import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/retry.dart';
import '../data/titles_repository.dart';
import '../domain/media_title.dart';

part 'title_search_provider.g.dart';

/// Search results for one query. A function parameter = a "family": each
/// distinct query string gets its own provider instance (and its own cache).
///
/// Auto-dispose (because keepAlive defaults to false): when the screen stops
/// watching "dun", that instance is destroyed. That's what makes défi 2 possible.
@Riverpod(retry: retryTransient)
Future<List<MediaTitle>> titleSearch(Ref ref, String query) async {
  final q = query.trim();
  // Same rule as the API DTO (Length 2..100): don't even send a request that would get a 400.
  if (q.length < 2) return const [];

  // TODO(Léo) — DÉFI 2 : debounce + annulation.
  // Aujourd'hui, taper "dune" envoie 3 requêtes : "du", "dun", "dune".
  // À faire, dans cet ordre :
  //   1. Debounce : attendre 350 ms avant d'appeler l'API.
  //        await Future<void>.delayed(const Duration(milliseconds: 350));
  //      Si l'utilisateur a retapé une lettre entre-temps, l'écran ne regarde plus cette
  //      instance → Riverpod l'a disposée → `ref.mounted` est false : on abandonne
  //      (throw d'une petite exception à toi, ex. `SearchCancelled`).
  //   2. Annulation : si la requête est déjà partie et que l'instance est disposée,
  //      couper la requête HTTP. Crée un `CancelToken` (package dio), enregistre
  //      `ref.onDispose(cancelToken.cancel)` et passe-le à `repository.search(q, cancelToken: ...)`.
  //   3. Enlève le `skip:` du test « debounces fast typing » dans test/features/titles/search_screen_test.dart.
  // Question d'entretien : pourquoi le debounce seul ne suffit pas (pense à une API lente à 2 s) ?
  return ref.watch(titlesRepositoryProvider).search(q);
}
