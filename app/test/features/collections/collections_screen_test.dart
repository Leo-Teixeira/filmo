import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/collections/data/collections_repository.dart';
import 'package:filmo/features/collections/domain/collection_entry.dart';
import 'package:filmo/features/collections/presentation/collections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_collections_repository.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  FakeCollectionsRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [collectionsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CollectionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('never prints the invite code; only the owner can copy it', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FakeCollectionsRepository([
        fakeCollection(),
        fakeCollection(
          id: 'col-2',
          name: 'Chez Sam',
          role: CollectionRole.member,
        ),
      ]),
    );
    expect(find.textContaining('ABCDEFGHJK'), findsNothing);

    await tester.tap(find.byTooltip('Actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Copier le code d\'invitation'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Actions').last);
    await tester.pumpAndSettle();
    expect(find.text('Copier le code d\'invitation'), findsNothing);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    final repo = FakeCollectionsRepository([fakeCollection()])
      ..failure = const ApiNotFound();
    await pumpScreen(tester, repo);
    expect(find.text('Introuvable.'), findsOneWidget);

    repo.failure = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Soirées'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await pumpScreen(tester, FakeCollectionsRepository());

    expect(
      find.text('Crée une collection ou rejoins celle d\'un ami.'),
      findsOneWidget,
    );
  });

  testWidgets('creates a collection from the dialog', (tester) async {
    await pumpScreen(tester, FakeCollectionsRepository());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pump();
    expect(find.text('Champ requis.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Films');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Films'), findsOneWidget);
  });

  testWidgets('keeps the join dialog open with a clear error', (tester) async {
    final repo = FakeCollectionsRepository()..failure = const ApiNotFound();
    await pumpScreen(tester, repo);

    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Rejoindre'));
    await tester.pump();
    expect(find.textContaining('10 caractères'), findsOneWidget);
    expect(repo.joinedCodes, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'zzzzzzzzzz');
    await tester.tap(find.widgetWithText(FilledButton, 'Rejoindre'));
    await tester.pumpAndSettle();

    expect(find.text('Code d\'invitation invalide.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    repo.failure = const ApiConflict();
    await tester.tap(find.widgetWithText(FilledButton, 'Rejoindre'));
    await tester.pumpAndSettle();
    expect(find.text('Tu es déjà membre de cette collection.'), findsOneWidget);
  });

  testWidgets('owner delete: cancel keeps it, a failure shows a snackbar', (
    tester,
  ) async {
    final repo = FakeCollectionsRepository([fakeCollection()]);
    await pumpScreen(tester, repo);

    Future<void> askDelete() async {
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
    }

    await askDelete();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repo.stored, hasLength(1));

    repo.failure = const ApiOffline();
    await askDelete();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text(const ApiOffline().message), findsOneWidget);
    expect(find.text('Soirées'), findsOneWidget);
  });

  testWidgets('a member can leave after confirming', (tester) async {
    await pumpScreen(
      tester,
      FakeCollectionsRepository([
        fakeCollection(name: 'Chez Sam', role: CollectionRole.member),
      ]),
    );

    await tester.tap(find.byTooltip('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer'), findsNothing);
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(find.text('Chez Sam'), findsNothing);
  });

  group('members dialog', () {
    Future<void> openMembers(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir les membres'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists every member once loaded, and closes', (tester) async {
      await pumpScreen(tester, FakeCollectionsRepository([fakeCollection()]));

      await openMembers(tester);

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Léo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Sam')),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows the error inside the dialog and retries', (
      tester,
    ) async {
      final repo = FakeCollectionsRepository([fakeCollection()]);
      await pumpScreen(tester, repo);

      repo.failure = const ApiNotFound();
      await openMembers(tester);

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Introuvable.')),
        findsOneWidget,
      );
      expect(find.text('Sam'), findsNothing);

      repo.failure = null;
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Réessayer')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: dialog, matching: find.text('Sam')),
        findsOneWidget,
      );
    });
  });
}
