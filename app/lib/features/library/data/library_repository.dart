import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

part 'library_repository.g.dart';

class LibraryRepository {
  LibraryRepository(this._dio);

  final Dio _dio;

  Future<List<LibraryEntry>?> userLibrary(String? status) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/library',
        queryParameters: status != null ? {'status': status} : null,
      );
      return response.data!
          .map((res) => LibraryEntry.fromJson(res as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.fromDio(e);
    }
  }

  /// Null when the title is not in my library (the API answers 404).
  Future<LibraryEntry?> find(String titleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_path(titleId));
      return LibraryEntry.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.fromDio(e);
    }
  }

  /// [rating] null clears the rating on the server.
  Future<LibraryEntry> save(
    String titleId, {
    required WatchStatus status,
    int? rating,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        _path(titleId),
        data: {'status': status.apiValue, 'rating': rating},
      );
      return LibraryEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Idempotent: an entry that is already gone counts as removed.
  Future<void> remove(String titleId) async {
    try {
      await _dio.delete<void>(_path(titleId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ApiFailure.fromDio(e);
    }
  }

  // Encoded: the id may come from a deep link and must never escape /library/.
  String _path(String titleId) => '/library/${Uri.encodeComponent(titleId)}';
}

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) =>
    LibraryRepository(ref.watch(dioProvider));
