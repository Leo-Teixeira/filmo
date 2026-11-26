import '../../../core/network/api_failure.dart';

// Mirrors the API's DTO rules so most errors are caught before a request.
abstract final class CollectionValidators {
  // 10 chars, no 0/O/1/I.
  static final _inviteCodePattern = RegExp(r'^[A-HJ-NP-Z2-9]{10}$');

  static String normalizeInviteCode(String raw) => raw.trim().toUpperCase();

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Champ requis.';
    return v.length > 80 ? '80 caractères maximum.' : null;
  }

  static String? inviteCode(String? value) =>
      _inviteCodePattern.hasMatch(normalizeInviteCode(value ?? ''))
      ? null
      : 'Le code fait 10 caractères (lettres et chiffres).';

  static String joinError(Object error) => switch (error) {
    ApiNotFound() || ApiInvalidRequest() => 'Code d\'invitation invalide.',
    ApiConflict() => 'Tu es déjà membre de cette collection.',
    _ => userMessage(error),
  };
}
