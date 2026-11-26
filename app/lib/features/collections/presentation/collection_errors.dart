import '../../../core/network/api_failure.dart';

String joinErrorMessage(Object error) => switch (error) {
  ApiNotFound() || ApiInvalidRequest() => 'Code d\'invitation invalide.',
  ApiConflict() => 'Tu es déjà membre de cette collection.',
  _ => userMessage(error),
};
