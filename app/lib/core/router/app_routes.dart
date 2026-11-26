/// Separate from app_router.dart to avoid a circular import with the screens.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/';
  static const search = '/search';
  static const collections = '/collections';

  static const libraryStatusPattern = '/library/:status';
  static const titleDetailPattern = '/titles/:id';

  static String titleDetail(String id) => '/titles/$id';
  static String libraryStatus(String status) => '/library/$status';
}
