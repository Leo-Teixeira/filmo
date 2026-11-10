/// Everything TMDB-specific on the client side. The API never sends full image
/// URLs (only `posterPath` like "/abc.jpg"): the client picks the size it needs.
abstract final class Tmdb {
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p';

  /// TMDB sizes for posters: w92, w154, w185, w342, w500, w780, original.
  /// w185 for list thumbnails, w342 for the detail screen: never "original" (several MB).
  static String? posterUrl(String? path, {String size = 'w342'}) =>
      path == null ? null : '$_imageBaseUrl/$size$path';

  /// Mandatory notice from TMDB's terms of use, kept in English as TMDB requires.
  static const attribution =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
}
