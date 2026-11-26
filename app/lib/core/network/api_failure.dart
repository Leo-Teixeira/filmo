import 'package:dio/dio.dart';

sealed class ApiFailure implements Exception {
  const ApiFailure(this.message);

  final String message;

  bool get isTransient => false;

  @override
  String toString() => message;

  static ApiFailure fromDio(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      null => const ApiOffline(),
      401 => const ApiUnauthorized(),
      400 => const ApiInvalidRequest(),
      404 => const ApiNotFound(),
      409 => const ApiConflict(),
      // The API maps TMDB's 429 to 503: not transient, don't hammer.
      503 => const ApiBusy(),
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

final class ApiConflict extends ApiFailure {
  const ApiConflict() : super('Action impossible dans l\'état actuel.');
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

/// Non-ApiFailure errors get a generic message: never show raw Dart error text.
String userMessage(Object error) =>
    error is ApiFailure ? error.message : 'Une erreur inattendue est survenue.';
