import 'package:freezed_annotation/freezed_annotation.dart';

import '../../titles/domain/media_title.dart';
import 'watch_status.dart';

part 'library_entry.freezed.dart';
part 'library_entry.g.dart';

/// One row of "my library" (the UserTitle table), as returned by /library endpoints.
/// No userId field: the API omits it (`omit: { userId: true }`), the client doesn't need it.
@freezed
abstract class LibraryEntry with _$LibraryEntry {
  const factory LibraryEntry({
    required String titleId,
    required WatchStatus status,
    // 1..10, null = not rated yet.
    int? rating,
    // Set by the API when the status becomes "completed".
    DateTime? watchedAt,
    // Embedded by the API (include: { title: true }), so the library list can show posters without N extra calls.
    required MediaTitle title,
  }) = _LibraryEntry;

  factory LibraryEntry.fromJson(Map<String, dynamic> json) =>
      _$LibraryEntryFromJson(json);
}
