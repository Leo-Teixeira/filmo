import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../titles/domain/media_title.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';
import 'library_entry_controller.dart';

class LibrarySection extends ConsumerWidget {
  const LibrarySection({super.key, required this.title});

  /// The whole title, not just its id: needed for the optimistic first add.
  final MediaTitle title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(libraryEntryControllerProvider(title.id));

    return switch (entry) {
      AsyncData(:final value) => _Controls(title: title, entry: value),
      AsyncError(:final error) => Text(userMessage(error)),
      _ => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.title, required this.entry});

  final MediaTitle title;
  final LibraryEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      libraryEntryControllerProvider(title.id).notifier,
    );
    final current = entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<WatchStatus>(
          segments: [
            for (final status in WatchStatus.values)
              ButtonSegment(
                value: status,
                icon: Icon(_icons[status]),
                label: Text(status.label),
              ),
          ],
          selected: {?current?.status},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            // Ignore deselecting: removing goes through the "Retirer" button.
            if (selection.isEmpty) return;
            _run(
              context,
              () => controller.setStatus(selection.first, title: title),
            );
          },
        ),
        if (current != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Ma note'),
              const SizedBox(width: 12),
              DropdownButton<int?>(
                value: current.rating,
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (var note = 1; note <= 10; note++)
                    DropdownMenuItem(value: note, child: Text('$note/10')),
                ],
                onChanged: (rating) =>
                    _run(context, () => controller.setRating(rating)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _run(context, controller.remove),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Retirer'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    // Grab the messenger before the await: the widget may be gone after it.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      // Catch everything: an unexpected bug must still give feedback.
      messenger.showSnackBar(SnackBar(content: Text(userMessage(error))));
    }
  }
}

const _icons = {
  WatchStatus.wantToWatch: Icons.bookmark_border,
  WatchStatus.watching: Icons.play_circle_outline,
  WatchStatus.completed: Icons.check_circle_outline,
  WatchStatus.dropped: Icons.cancel_outlined,
};
