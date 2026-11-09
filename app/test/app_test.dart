import 'package:filmo/app.dart';
import 'package:filmo/features/auth/data/auth_repository.dart';
import 'package:filmo/features/auth/domain/auth_exception.dart';
import 'package:filmo/features/auth/domain/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = User(id: '1', email: 'leo@filmo.local', displayName: 'Léo');

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? session, this.meFails = false})
    : _session = session;

  User? _session;
  final bool meFails;
  bool loggedOut = false;

  @override
  Future<User?> currentUser() async {
    if (meFails && _session != null) {
      throw const AuthException('API injoignable.');
    }
    return _session;
  }

  @override
  Future<void> login({required String email, required String password}) async {
    if (password != 'password123') {
      throw const AuthException('Email ou mot de passe incorrect.');
    }
    _session = _user;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _session = _user;

  @override
  Future<void> logout() async {
    loggedOut = true;
    _session = null;
  }
}

Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const FilmoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fillLogin(WidgetTester tester, String password) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'leo@filmo.local',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Mot de passe'),
    password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed out user lands on the auth screen', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
  });

  testWidgets('successful login redirects to home, logout comes back', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());

    await fillLogin(tester, 'password123');
    expect(find.text('Bonjour Léo'), findsOneWidget);

    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
  });

  testWidgets('failed login shows the error and stays on auth', (tester) async {
    await pumpApp(tester, FakeAuthRepository());

    await fillLogin(tester, 'wrong-password');

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Bonjour Léo'), findsNothing);
  });

  testWidgets('existing session opens straight on home', (tester) async {
    await pumpApp(tester, FakeAuthRepository(session: _user));

    expect(find.text('Bonjour Léo'), findsOneWidget);
  });

  testWidgets('drops the stored token when /me fails right after login', (
    tester,
  ) async {
    final repo = FakeAuthRepository(meFails: true);
    await pumpApp(tester, repo);

    await fillLogin(tester, 'password123');

    expect(find.text('API injoignable.'), findsOneWidget);
    expect(repo.loggedOut, isTrue);
    expect(find.text('Bonjour Léo'), findsNothing);
  });
}
