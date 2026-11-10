import 'package:flutter/material.dart';

import '../../../../core/config/tmdb.dart';

/// TMDB's terms require this notice wherever their data is shown.
/// TODO(Léo): add the official TMDB logo (assets/tmdb_logo.svg from
/// themoviedb.org/about/logos-attribution) next to the text, and an "À propos" screen later.
class TmdbAttribution extends StatelessWidget {
  const TmdbAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        Tmdb.attribution,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
