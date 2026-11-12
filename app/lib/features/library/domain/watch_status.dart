import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum WatchStatus {
  wantToWatch('À voir'),
  watching('En cours'),
  completed('Vu'),
  dropped('Abandonné');

  const WatchStatus(this.label);

  final String label;

  /// Must match the JSON annotation: the repository builds the PUT body by hand.
  String get apiValue => switch (this) {
    WatchStatus.wantToWatch => 'WANT_TO_WATCH',
    WatchStatus.watching => 'WATCHING',
    WatchStatus.completed => 'COMPLETED',
    WatchStatus.dropped => 'DROPPED',
  };
}
