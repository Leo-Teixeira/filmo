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
  testWidgets('shows the invite code to the owner only', (tester) async {
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

    expect(find.textContaining('code ABCDEFGHJK'), findsOneWidget);
    expect(find.text('Chez Sam'), findsOneWidget);
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
}
