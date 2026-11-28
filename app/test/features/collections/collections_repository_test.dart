import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/collections/data/collections_repository.dart';
import 'package:filmo/features/collections/domain/collection_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status] and [body], and records what was sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, [this.body]);

  final int status;
  final Object? body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _summary = {
  'id': 'col-1',
  'name': 'Soirées',
  'role': 'OWNER',
  'inviteCode': 'ABCDEFGHJK',
  'itemCount': 0,
  'memberCount': 1,
  'createdAt': '2026-11-26T10:00:00.000Z',
};

(CollectionsRepository, _StubAdapter) _repo(int status, [Object? body]) {
  final adapter = _StubAdapter(status, body);
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = adapter;
  return (CollectionsRepository(dio), adapter);
}

void main() {
  test('parses the API summary, role included', () async {
    final (repo, adapter) = _repo(200, [
      _summary,
      {..._summary, 'id': 'col-2', 'role': 'MEMBER', 'inviteCode': null},
    ]);

    final list = await repo.listMine();

    expect(adapter.requests.single.path, '/collections');
    expect(list.first.isOwner, isTrue);
    expect(list.last.role, CollectionRole.member);
    expect(list.last.inviteCode, isNull);
    expect(list.first.createdAt, DateTime.utc(2026, 11, 26, 10));
  });

  test('joins with the code in the body, not the URL', () async {
    final (repo, adapter) = _repo(201, _summary);

    await repo.join('ABCDEFGHJK');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/collections/join');
    expect(request.data, {'inviteCode': 'ABCDEFGHJK'});
  });

  test('maps 409 on join to ApiConflict', () async {
    final (repo, _) = _repo(409);

    await expectLater(repo.join('ABCDEFGHJK'), throwsA(isA<ApiConflict>()));
  });

  test('leave posts to /collections/:id/leave', () async {
    final (repo, adapter) = _repo(204);

    await repo.leave('col-1');

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/collections/col-1/leave');
  });

  test('delete and leave treat 404 as already done', () async {
    final (repo, _) = _repo(404);

    await repo.delete('col-1');
    await repo.leave('col-1');
  });

  test('leave as owner surfaces the 409', () async {
    final (repo, _) = _repo(409);

    await expectLater(repo.leave('col-1'), throwsA(isA<ApiConflict>()));
  });
}
