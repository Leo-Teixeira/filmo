import 'package:dio/dio.dart';
import 'package:filmo/features/collections/domain/collection_members_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/collection_entry.dart';

part 'collections_repository.g.dart';

class CollectionsRepository {
  CollectionsRepository(this._dio);

  final Dio _dio;

  Future<List<CollectionEntry>> listMine() => _call(() async {
    final response = await _dio.get<List<dynamic>>('/collections');
    return response.data!
        .map((json) => CollectionEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  });

  Future<CollectionEntry> create(String name) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/collections',
      data: {'name': name},
    );
    return CollectionEntry.fromJson(response.data!);
  });

  Future<CollectionEntry> join(String inviteCode) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/collections/join',
      data: {'inviteCode': inviteCode},
    );
    return CollectionEntry.fromJson(response.data!);
  });

  /// Idempotent: a collection already gone (deleted by its owner, or left) counts as done.
  Future<void> delete(String id) =>
      _doneIfGone(() => _dio.delete<void>(_path(id)));

  Future<void> leave(String id) =>
      _doneIfGone(() => _dio.post<void>('${_path(id)}/leave'));

  String _path(String id) => '/collections/${Uri.encodeComponent(id)}';

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> _doneIfGone(Future<void> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<CollectionMembersEntry>> showMembers(String collectionId) async {
    final response = await _dio.get<List<dynamic>>(
      '${_path(collectionId)}/members',
    );

    return response.data!
        .map(
          (member) =>
              CollectionMembersEntry.fromJson(member as Map<String, dynamic>),
        )
        .toList();
  }
}

@Riverpod(keepAlive: true)
CollectionsRepository collectionsRepository(Ref ref) =>
    CollectionsRepository(ref.watch(dioProvider));
