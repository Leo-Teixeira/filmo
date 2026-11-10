import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../library/presentation/library_section.dart';
import '../domain/media_title.dart';
import 'title_detail_provider.dart';
import 'widgets/poster.dart';
import 'widgets/tmdb_attribution.dart';

/// Detail screen for /titles/:id. Receives only the id from the router:
/// the data is (re)loaded from the API, so a deep link works without passing through search.
class TitleDetailScreen extends ConsumerWidget {
  const TitleDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(titleDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(title.value?.title ?? '')),
      body: switch (title) {
        AsyncData(:final value) => _Details(title: value),
        AsyncError(:final error) => Center(child: Text(userMessage(error))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.title});

  final MediaTitle title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Poster(path: title.posterPath, width: 120),
            const SizedBox(width: 16),
            // Expanded: without it, a long title overflows the Row instead of wrapping.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LibrarySection(title: title),
        const SizedBox(height: 20),
        Text(title.overview ?? 'Pas de synopsis disponible.'),
        const TmdbAttribution(),
      ],
    );
  }
}
