import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_exception.dart';
import '../domain/user.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> login({required String email, required String password}) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) => _authenticate('/auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
  });

  /// Returns null when there is no session, the token was rejected, or the
  /// account no longer exists.
  Future<User?> currentUser() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 404) {
        await _tokenStorage.clear();
        return null;
      }
      throw _toAuthException(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<void> _authenticate(String path, Map<String, String> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final token = response.data?['accessToken'];
      if (token is! String) {
        throw const AuthException('Réponse inattendue du serveur.');
      }
      await _tokenStorage.saveAccessToken(token);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  AuthException _toAuthException(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      401 => const AuthException('Email ou mot de passe incorrect.'),
      409 => const AuthException('Un compte existe déjà avec cet email.'),
      400 => AuthException(_validationMessage(e.response?.data)),
      null => const AuthException(
        'API injoignable. Vérifie que le serveur Nest tourne.',
      ),
      _ => AuthException('Erreur serveur ($status).'),
    };
  }

  // Nest's ValidationPipe returns `message` as a string or a list of strings.
  String _validationMessage(Object? data) {
    final message = data is Map ? data['message'] : null;
    if (message is List && message.isNotEmpty) return message.join('\n');
    if (message is String) return message;
    return 'Données invalides.';
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
