import 'package:json_annotation/json_annotation.dart';

/// Mirrors the Prisma enum WatchStatus. screamingSnake: wantToWatch <-> "WANT_TO_WATCH".
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum WatchStatus {
  wantToWatch('À voir'),
  watching('En cours'),
  completed('Vu'),
  dropped('Abandonné');

  const WatchStatus(this.label);

  /// French label. Icons live in presentation (library_section.dart): the domain doesn't import Flutter.
  final String label;

  /// Value sent to the API. Same rule as the JSON annotation, written once here
  /// because the repository builds the PUT body by hand.
  String get apiValue => switch (this) {
    WatchStatus.wantToWatch => 'WANT_TO_WATCH',
    WatchStatus.watching => 'WATCHING',
    WatchStatus.completed => 'COMPLETED',
    WatchStatus.dropped => 'DROPPED',
  };
}
