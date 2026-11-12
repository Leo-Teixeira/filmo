import 'dart:async';

import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/features/library/data/library_repository.dart';
import 'package:filmo/features/library/domain/library_entry.dart';
import 'package:filmo/features/library/domain/watch_status.dart';
import 'package:filmo/features/titles/domain/media_title.dart';

const fakeTitle = MediaTitle(
  id: 'dune-uuid',
  type: TitleType.movie,
  isAnime: false,
  title: 'Dune',
);

/// In-memory fake. `pending` lets a test freeze the server answer to look at the state in between.
class FakeLibraryRepository implements LibraryRepository {
  LibraryEntry? stored;
  ApiFailure? failure;
  Completer<void>? pending;
  int saves = 0;

  @override
  Future<LibraryEntry?> find(String titleId) async => stored;

  @override
  Future<LibraryEntry> save(
    String titleId, {
    required WatchStatus status,
    int? rating,
  }) async {
    saves++;
    await pending?.future;
    if (failure != null) throw failure!;
    return stored = LibraryEntry(
      titleId: titleId,
      status: status,
      rating: rating,
      title: fakeTitle,
    );
  }

  @override
  Future<void> remove(String titleId) async => stored = null;
}
