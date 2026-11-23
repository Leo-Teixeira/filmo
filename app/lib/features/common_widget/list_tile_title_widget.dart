import 'package:filmo/core/router/app_routes.dart';
import 'package:filmo/features/common_widget/poster.dart';
import 'package:filmo/features/titles/domain/media_title.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListTileTitleComponent extends StatelessWidget {
  const ListTileTitleComponent({super.key, required this.libraryTitle});

  final MediaTitle libraryTitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Poster(path: libraryTitle.posterPath, width: 40, size: 'w92'),
      title: Text(libraryTitle.title),
      subtitle: Text(libraryTitle.subtitle),
      // push, not go: back returns to the results.
      onTap: () => context.push(AppRoutes.titleDetail(libraryTitle.id)),
    );
  }
}
