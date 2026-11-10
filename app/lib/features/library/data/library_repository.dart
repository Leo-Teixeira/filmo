import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

part 'library_repository.g.dart';

/// Talks to /library. No user id anywhere: the API reads it from the token
/// that dioProvider's interceptor adds to every request.
class LibraryRepository {
  LibraryRepository(this._dio);

  final Dio _dio;

  /// Returns null when the title is not in my library (the API answers 404).
  /// Here a 404 is a normal answer ("not added yet"), not an error to display.
  Future<LibraryEntry?> find(String titleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_path(titleId));
      return LibraryEntry.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.fromDio(e);
    }
  }

  /// PUT = create or replace. [rating] null clears the rating on the server.
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

  /// Idempotent: removing an entry that is already gone (other device, double tap) is a success.
  Future<void> remove(String titleId) async {
    try {
      await _dio.delete<void>(_path(titleId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ApiFailure.fromDio(e);
    }
  }

  // Encoded: the id may come from a URL (deep link), it must never escape /library/.
  String _path(String titleId) => '/library/${Uri.encodeComponent(titleId)}';
}

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) =>
    LibraryRepository(ref.watch(dioProvider));
