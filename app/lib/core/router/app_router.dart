import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/titles/presentation/search_screen.dart';
import '../../features/titles/presentation/title_detail_screen.dart';
import 'app_routes.dart';

export 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Bridges Riverpod to go_router: re-run `redirect` whenever the session changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (!session.hasValue) {
        return session.isLoading ? AppRoutes.splash : AppRoutes.auth;
      }
      final signedIn = session.value != null;
      if (!signedIn) return location == AppRoutes.auth ? null : AppRoutes.auth;
      if (location == AppRoutes.auth || location == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // Both routes sit behind the redirect above: signed-out users are sent to /auth.
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.titleDetailPattern,
        // The id comes from the URL; the screen loads the title itself (deep-link friendly).
        builder: (context, state) =>
            TitleDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
}
