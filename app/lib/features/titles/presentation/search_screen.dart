import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/router/app_routes.dart';
import '../domain/media_title.dart';
import 'title_search_provider.dart';
import 'widgets/poster.dart';
import 'widgets/tmdb_attribution.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(titleSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          // Same max as the API DTO.
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'Film, série, animé…',
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: switch (results) {
        AsyncData(:final value) => _Results(
          titles: value,
          queryTooShort: _query.trim().length < 2,
        ),
        AsyncError(:final error) => _Message(
          icon: Icons.cloud_off,
          text: userMessage(error),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.titles, required this.queryTooShort});

  final List<MediaTitle> titles;
  final bool queryTooShort;

  @override
  Widget build(BuildContext context) {
    if (queryTooShort) {
      return const _Message(
        icon: Icons.search,
        text: 'Tape au moins 2 lettres pour chercher.',
      );
    }
    if (titles.isEmpty) {
      return const _Message(icon: Icons.search_off, text: 'Aucun résultat.');
    }
    return ListView.builder(
      // +1 row for the TMDB attribution at the bottom of the list.
      itemCount: titles.length + 1,
      itemBuilder: (context, index) {
        if (index == titles.length) return const TmdbAttribution();
        final title = titles[index];
        return ListTile(
          leading: Poster(path: title.posterPath, width: 40, size: 'w92'),
          title: Text(title.title),
          subtitle: Text(title.subtitle),
          // push, not go: back returns to the results.
          onTap: () => context.push(AppRoutes.titleDetail(title.id)),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
