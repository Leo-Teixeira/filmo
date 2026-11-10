/// Route paths, in their own file so screens can navigate without importing
/// app_router.dart (which imports every screen: that would be a circular import).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/';
  static const search = '/search';

  /// Pattern registered in GoRouter. `:id` is read back with state.pathParameters['id'].
  static const titleDetailPattern = '/titles/:id';

  /// Concrete path to navigate to. A function, so no screen builds '/titles/$id' by hand.
  static String titleDetail(String id) => '/titles/$id';
}
