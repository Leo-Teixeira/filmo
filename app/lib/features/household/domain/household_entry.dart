import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_entry.freezed.dart';
part 'household_entry.g.dart';

@freezed
abstract class HouseholdEntry with _$HouseholdEntry {
  const factory HouseholdEntry({
    required String id,
    required String name,
    required String inviteCode,
  }) = _HouseholdEntry;

  factory HouseholdEntry.fromJson(Map<String, dynamic> json) =>
      _$HouseholdEntryFromJson(json);
}
