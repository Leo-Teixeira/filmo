// Mirrors the API's DTO rules so most errors are caught before a request.
abstract final class CollectionValidators {
  static const inviteCodeLength = 10;
  static const nameMaxLength = 80;
  static final _inviteCodeAlphabet = RegExp(r'^[A-HJ-NP-Z2-9]*$');

  static String normalizeInviteCode(String raw) => raw.trim().toUpperCase();

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Champ requis.';
    return v.length > nameMaxLength ? '80 caractères maximum.' : null;
  }

  static String? inviteCode(String? value) {
    final v = normalizeInviteCode(value ?? '');
    if (v.length != inviteCodeLength) return 'Le code fait 10 caractères.';
    return _inviteCodeAlphabet.hasMatch(v)
        ? null
        : 'Le code ne contient ni 0, ni O, ni 1, ni I.';
  }
}
