import 'package:flutter/material.dart';

import '../../../../core/config/tmdb.dart';

/// TMDB poster with a neutral placeholder. Shared by the search list and the detail screen.
class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.path,
    required this.width,
    this.size = 'w342',
  });

  final String? path;
  final double width;

  /// TMDB size bucket, see Tmdb.posterUrl.
  final String size;

  @override
  Widget build(BuildContext context) {
    final url = Tmdb.posterUrl(path, size: size);
    // Posters are 2:3. Fixing the ratio avoids the list "jumping" while images load.
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: width * 1.5,
        child: url == null
            ? const _Placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                // Without errorBuilder, a broken image shows a red error box (and fails widget tests).
                errorBuilder: (_, _, _) => const _Placeholder(),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined, color: colors.onSurfaceVariant),
    );
  }
}
