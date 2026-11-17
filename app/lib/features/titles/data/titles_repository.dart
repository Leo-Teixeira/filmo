import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/media_title.dart';

part 'titles_repository.g.dart';

class TitlesRepository {
  TitlesRepository(this._dio);

  final Dio _dio;

  Future<List<MediaTitle>> search(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/titles',
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );
      return response.data!
          .map((json) => MediaTitle.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Not a failure: rethrown untouched so callers can detect it with CancelToken.isCancel.
      if (CancelToken.isCancel(e)) rethrow;
      throw ApiFailure.fromDio(e);
    }
  }

  Future<MediaTitle> getById(String id) async {
    try {
      // Encoded: a crafted deep link like "..%2Flibrary" must not reach another API route.
      final response = await _dio.get<Map<String, dynamic>>(
        '/titles/${Uri.encodeComponent(id)}',
      );
      return MediaTitle.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

@Riverpod(keepAlive: true)
TitlesRepository titlesRepository(Ref ref) =>
    TitlesRepository(ref.watch(dioProvider));
