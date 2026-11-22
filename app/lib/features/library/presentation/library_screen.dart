import 'package:filmo/features/common_widget/list_tile_title_widget.dart';
import 'package:filmo/features/library/domain/watch_status.dart';
import 'package:filmo/features/library/presentation/providers/library_provider.dart';
import 'package:filmo/features/titles/domain/media_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(userLibraryProvider(status));
    return Scaffold(
      appBar: AppBar(title: Text('Ma bibliothèque')),
      body: library.when(
        data: (library) => library != null
            ? ListView.builder(
                itemCount: library.length,
                itemBuilder: (context, i) {
                  MediaTitle title = library[i].title;
                  return ListTileTitleComponent(libraryTitle: title);
                },
              )
            : null,
        error: (err, stackTrace) => Center(child: Text(err.toString())),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
