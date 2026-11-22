import 'package:flutter/material.dart';

import '../../../../core/config/tmdb.dart';

/// TODO(Léo): add the official TMDB logo (themoviedb.org/about/logos-attribution) and an "À propos" screen.
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
