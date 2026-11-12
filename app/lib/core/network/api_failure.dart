import 'package:dio/dio.dart';

/// Every way an API call can fail, as the UI needs to know it.
///
/// `sealed` = the compiler knows the complete list of subclasses, so a
/// `switch (failure)` without a default case is checked for exhaustiveness.
/// Add a subclass and every switch that forgot it stops compiling.
sealed class ApiFailure implements Exception {
  const ApiFailure(this.message);

  /// French message, ready to show in a SnackBar or an error state.
  final String message;

  /// True when retrying later might succeed (network, TMDB down).
  /// A 404 or a 400 will fail the same way forever: no point retrying.
  bool get isTransient => false;

  @override
  String toString() => message;

  /// Single translation point Dio → domain. Repositories call this in their
  /// `on DioException catch` so screens never see a DioException.
  static ApiFailure fromDio(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      // No response: server down, no network, timeout.
      null => const ApiOffline(),
      // Expired or invalid token. TODO(Léo): later, an interceptor should log the user out on 401.
      401 => const ApiUnauthorized(),
      // Rejected by the API's ValidationPipe: retrying the same request is pointless.
      400 => const ApiInvalidRequest(),
      404 => const ApiNotFound(),
      // TMDB rate-limits us (the API maps its 429 to 503): wait, don't hammer.
      503 => const ApiBusy(),
      // 502/504: our API is up, but TMDB behind it isn't (see TmdbProvider on the API side).
      502 || 504 => const ApiUpstreamDown(),
      _ => ApiUnexpected(status),
    };
  }
}

final class ApiOffline extends ApiFailure {
  const ApiOffline()
    : super('API injoignable. Vérifie ta connexion ou que le serveur tourne.');

  @override
  bool get isTransient => true;
}

final class ApiUnauthorized extends ApiFailure {
  const ApiUnauthorized() : super('Session expirée, reconnecte-toi.');
}

final class ApiInvalidRequest extends ApiFailure {
  const ApiInvalidRequest() : super('Requête refusée par le serveur.');
}

final class ApiBusy extends ApiFailure {
  const ApiBusy() : super('Trop de demandes, réessaie dans une minute.');
}

final class ApiNotFound extends ApiFailure {
  const ApiNotFound() : super('Introuvable.');
}

final class ApiUpstreamDown extends ApiFailure {
  const ApiUpstreamDown()
    : super('Le catalogue ne répond pas, réessaie dans un instant.');

  @override
  bool get isTransient => true;
}

final class ApiUnexpected extends ApiFailure {
  const ApiUnexpected(this.status) : super('Erreur serveur ($status).');

  final int status;
}

/// Text to show for ANY error caught in the UI. An ApiFailure has a French message;
/// anything else (a bug, a JSON parsing TypeError...) must not leak raw Dart text to the user.
String userMessage(Object error) =>
    error is ApiFailure ? error.message : 'Une erreur inattendue est survenue.';
