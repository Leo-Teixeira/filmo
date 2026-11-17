import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_title.freezed.dart';
part 'media_title.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TitleType {
  movie('Film'),
  tv('Série');

  const TitleType(this.label);

  final String label;
}

/// Not named Title: it would clash with the Title widget exported by material.dart.
@freezed
abstract class MediaTitle with _$MediaTitle {
  const MediaTitle._();

  const factory MediaTitle({
    /// Our uuid, not TMDB's id.
    required String id,
    required TitleType type,
    required bool isAnime,
    required String title,
    String? overview,
    String? posterPath,
    DateTime? releaseDate,
  }) = _MediaTitle;

  factory MediaTitle.fromJson(Map<String, dynamic> json) =>
      _$MediaTitleFromJson(json);

  int? get year => releaseDate?.year;

  String get subtitle =>
      [type.label, if (year != null) '$year', if (isAnime) 'Animé'].join(' · ');
}
