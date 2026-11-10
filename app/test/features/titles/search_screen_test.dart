import 'package:dio/dio.dart';
import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/core/router/app_routes.dart';
import 'package:filmo/features/titles/data/titles_repository.dart';
import 'package:filmo/features/titles/domain/media_title.dart';
import 'package:filmo/features/titles/presentation/search_screen.dart';
import 'package:filmo/features/titles/presentation/title_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _dune = MediaTitle(
  id: 'dune-uuid',
  type: TitleType.movie,
  isAnime: false,
  title: 'Dune',
  overview: 'Paul Atreides…',
  releaseDate: DateTime(2021, 9, 15),
);

/// Fake repository: no Dio, no network. Records every search so tests can count requests.
class FakeTitlesRepository implements TitlesRepository {
  FakeTitlesRepository({this.failure});

  final ApiFailure? failure;
  final searches = <String>[];

  @override
  Future<List<MediaTitle>> search(
    String query, {
    CancelToken? cancelToken,
  }) async {
    searches.add(query);
    if (failure != null) throw failure!;
    return query.toLowerCase().startsWith('du') ? [_dune] : [];
  }

  @override
  Future<MediaTitle> getById(String id) async => _dune;
}

/// Minimal app: just the two routes under test, without auth (the router redirect is tested in app_test.dart).
Future<void> pumpSearch(WidgetTester tester, FakeTitlesRepository repo) async {
  final router = GoRouter(
    initialLocation: AppRoutes.search,
    routes: [
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.titleDetailPattern,
        builder: (_, state) =>
            TitleDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [titlesRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for 2 letters, then lists results and opens the detail', (
    tester,
  ) async {
    final repo = FakeTitlesRepository();
    await pumpSearch(tester, repo);

    expect(find.text('Tape au moins 2 lettres pour chercher.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dune');
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Film · 2021'), findsOneWidget);

    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();
    expect(find.text('Paul Atreides…'), findsOneWidget);
    expect(
      find.textContaining('not endorsed or certified by TMDB'),
      findsOneWidget,
    );
  });

  testWidgets('shows the failure message', (tester) async {
    // Non-transient failure on purpose: a transient one would schedule retries (timers) in the test.
    final repo = FakeTitlesRepository(failure: const ApiUnexpected(500));
    await pumpSearch(tester, repo);

    await tester.enterText(find.byType(TextField), 'dune');
    await tester.pumpAndSettle();

    expect(find.text('Erreur serveur (500).'), findsOneWidget);
  });

  testWidgets(
    'debounces fast typing: only the last query hits the API',
    (tester) async {
      final repo = FakeTitlesRepository();
      await pumpSearch(tester, repo);

      // 3 keystrokes 100 ms apart, faster than the 350 ms debounce.
      for (final text in ['du', 'dun', 'dune']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.searches, ['dune']);
    },
    // TODO(Léo) — DÉFI 2 : enlève `skip: true` quand le debounce est en place.
    skip: true,
  );
}
