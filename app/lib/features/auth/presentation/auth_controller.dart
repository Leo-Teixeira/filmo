import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/user.dart';

part 'auth_controller.g.dart';

/// Session state: `AsyncData(null)` means signed out.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<User?> build() => ref.read(authRepositoryProvider).currentUser();

  // Errors are rethrown to the form instead of being stored in `state`, so a
  // failed login doesn't turn the session into AsyncError and trigger a redirect.
  Future<void> login({required String email, required String password}) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.login(email: email, password: password);
    state = AsyncData(await repository.currentUser());
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = AsyncData(await repository.currentUser());
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
