// Mirrors the API's DTO rules so most errors are caught before a request.
abstract final class AuthValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value) =>
      (value == null || value.isEmpty) ? 'Champ requis.' : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Champ requis.';
    return _emailPattern.hasMatch(v) ? null : 'Email invalide.';
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return '8 caractères minimum.';
    if (v.length > 128) return '128 caractères maximum.';
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Champ requis.';
    return v.length > 50 ? '50 caractères maximum.' : null;
  }
}
