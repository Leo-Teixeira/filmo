import 'package:freezed_annotation/freezed_annotation.dart';

import '../../titles/domain/media_title.dart';
import 'watch_status.dart';

part 'library_entry.freezed.dart';
part 'library_entry.g.dart';

@freezed
abstract class LibraryEntry with _$LibraryEntry {
  const factory LibraryEntry({
    required String titleId,
    required WatchStatus status,
    // 1..10, null = not rated yet.
    int? rating,
    // Set by the API when the status becomes "completed".
    DateTime? watchedAt,
    required MediaTitle title,
  }) = _LibraryEntry;

  factory LibraryEntry.fromJson(Map<String, dynamic> json) =>
      _$LibraryEntryFromJson(json);
}
