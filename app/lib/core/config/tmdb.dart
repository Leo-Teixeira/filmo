abstract final class Tmdb {
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p';

  /// w185 for lists, w342 for the detail screen; never "original" (several MB).
  static String? posterUrl(String? path, {String size = 'w342'}) =>
      path == null ? null : '$_imageBaseUrl/$size$path';

  /// Required by TMDB's terms of use, must stay in English.
  static const attribution =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
}
