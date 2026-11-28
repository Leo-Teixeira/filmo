import 'package:filmo/features/collections/domain/collection_entry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_members_entry.freezed.dart';
part 'collection_members_entry.g.dart';

@freezed
abstract class CollectionMembersEntry with _$CollectionMembersEntry {
  const factory CollectionMembersEntry({
    required CollectionRole role,
    required DateTime joinedAt,
    required MemberProfile user,
  }) = _CollectionMembersEntry;

  factory CollectionMembersEntry.fromJson(Map<String, dynamic> json) =>
      _$CollectionMembersEntryFromJson(json);
}

@freezed
abstract class MemberProfile with _$MemberProfile {
  const factory MemberProfile({
    required String id,
    required String displayName,
  }) = _MemberProfile;
  factory MemberProfile.fromJson(Map<String, dynamic> json) =>
      _$MemberProfileFromJson(json);
}
