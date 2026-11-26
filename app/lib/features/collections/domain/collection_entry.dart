import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_entry.freezed.dart';
part 'collection_entry.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CollectionRole { owner, member }

@freezed
abstract class CollectionEntry with _$CollectionEntry {
  const factory CollectionEntry({
    required String id,
    required String name,
    required CollectionRole role,
    // Only sent to the owner: only the owner may invite.
    String? inviteCode,
    required int itemCount,
    required int memberCount,
    required DateTime createdAt,
  }) = _CollectionEntry;

  factory CollectionEntry.fromJson(Map<String, dynamic> json) =>
      _$CollectionEntryFromJson(json);
}

extension CollectionEntryX on CollectionEntry {
  bool get isOwner => role == CollectionRole.owner;
}
