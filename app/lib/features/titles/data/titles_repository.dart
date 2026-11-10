import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/media_title.dart';

part 'titles_repository.g.dart';

/// Data layer: the only place that knows the /titles URLs and the JSON shape.
/// Screens and providers receive MediaTitle objects or an ApiFailure, never Dio types.
class TitlesRepository {
  TitlesRepository(this._dio);

  final Dio _dio;

  /// [cancelToken] lets the caller abort the HTTP request (used by défi 2:
  /// when the user keeps typing, the previous search is useless).
  Future<List<MediaTitle>> search(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/titles',
        // queryParameters encodes the value: "fast & furious" can't break the URL.
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );
      return response.data!
          .map((json) => MediaTitle.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // A cancelled request is not a failure to show: let it through untouched
      // so the caller can recognise it with CancelToken.isCancel(e).
      if (CancelToken.isCancel(e)) rethrow;
      throw ApiFailure.fromDio(e);
    }
  }

  Future<MediaTitle> getById(String id) async {
    try {
      // encodeComponent: the id comes from the URL (/titles/:id). A crafted deep link like
      // "..%2Flibrary" must not turn into a request to another route of our API.
      final response = await _dio.get<Map<String, dynamic>>(
        '/titles/${Uri.encodeComponent(id)}',
      );
      return MediaTitle.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

// keepAlive: the repository is stateless and cheap; no reason to rebuild it each time a screen closes.
@Riverpod(keepAlive: true)
TitlesRepository titlesRepository(Ref ref) =>
    TitlesRepository(ref.watch(dioProvider));
