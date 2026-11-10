import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_title.freezed.dart';
part 'media_title.g.dart';

/// Mirrors the Prisma enum. screamingSnake: `movie` <-> "MOVIE", `tv` <-> "TV" in JSON.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TitleType {
  movie('Film'),
  tv('Série');

  const TitleType(this.label);

  /// French label for the UI. Kept in the enum so no screen invents its own wording.
  final String label;
}

/// A film or a series as returned by GET /titles and GET /titles/:id.
///
/// Named MediaTitle, not Title: material.dart already exports a `Title`
/// widget, and every screen imports material.dart. Same name = import conflict.
@freezed
abstract class MediaTitle with _$MediaTitle {
  // Private constructor: required by freezed as soon as the class has its own getters (see `year`).
  const MediaTitle._();

  const factory MediaTitle({
    /// Our uuid (not TMDB's id): the one to send to /titles/:id and /library/:titleId.
    required String id,
    required TitleType type,
    required bool isAnime,
    required String title,
    String? overview,
    String? posterPath,
    DateTime? releaseDate,
  }) = _MediaTitle;

  // Unknown JSON keys (provider, externalId, cachedAt) are simply ignored.
  factory MediaTitle.fromJson(Map<String, dynamic> json) =>
      _$MediaTitleFromJson(json);

  int? get year => releaseDate?.year;

  /// "Série · 2011 · Animé" style subtitle, shared by the list and the detail screen.
  String get subtitle =>
      [type.label, if (year != null) '$year', if (isAnime) 'Animé'].join(' · ');
}
