import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../titles/domain/media_title.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';
import 'library_entry_controller.dart';

/// "My status" block shown on the title detail screen: status, rating, remove.
/// Pure UI: every action goes through LibraryEntryController.
class LibrarySection extends ConsumerWidget {
  const LibrarySection({super.key, required this.title});

  /// The whole title (not just its id): setStatus needs it for the optimistic update (défi 3).
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
    // .notifier = the controller object, to call its methods. read (not watch): we only call it in callbacks.
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
          // Empty set = not in my library yet: no segment selected.
          // `?expr` in a collection = null-aware element (Dart 3.8): adds nothing when expr is null.
          selected: {?current?.status},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            // Tapping the already-selected segment gives an empty set: we ignore it
            // (removing goes through the explicit "Retirer" button).
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

  /// Runs an action and turns an ApiFailure into a SnackBar. The controller rethrows, the UI displays.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    // Grab the messenger BEFORE the await: using `context` after an async gap is unsafe (widget may be gone).
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      // Catch everything (not only ApiFailure): an unexpected bug must still give feedback.
      messenger.showSnackBar(SnackBar(content: Text(userMessage(error))));
    }
  }
}

// Presentation concern, so it lives here and not in the domain enum (which stays Flutter-free).
const _icons = {
  WatchStatus.wantToWatch: Icons.bookmark_border,
  WatchStatus.watching: Icons.play_circle_outline,
  WatchStatus.completed: Icons.check_circle_outline,
  WatchStatus.dropped: Icons.cancel_outlined,
};
