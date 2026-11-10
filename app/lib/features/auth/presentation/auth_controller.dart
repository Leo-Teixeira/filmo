import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_exception.dart';
import '../domain/user.dart';

part 'auth_controller.g.dart';

/// Session state: `AsyncData(null)` means signed out.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<User?> build() => ref.read(authRepositoryProvider).currentUser();

  // Errors are rethrown to the form instead of being stored in `state`, so a
  // failed login doesn't turn the session into AsyncError and trigger a redirect.
  Future<void> login({required String email, required String password}) =>
      _authenticate((repo) => repo.login(email: email, password: password));

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) => _authenticate(
    (repo) => repo.register(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> _authenticate(
    Future<void> Function(AuthRepository repo) authenticate,
  ) async {
    final repository = ref.read(authRepositoryProvider);
    await authenticate(repository);
    try {
      final user = await repository.currentUser();
      if (user == null) {
        throw const AuthException('Session invalide, reconnecte-toi.');
      }
      state = AsyncData(user);
    } catch (_) {
      // The token is stored but the session can't be loaded: drop it so the
      // next app start doesn't silently sign the user in.
      await repository.logout();
      rethrow;
    }
  }
}
