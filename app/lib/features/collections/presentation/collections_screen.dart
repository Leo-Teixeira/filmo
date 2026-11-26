import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../domain/collection_entry.dart';
import 'collection_errors.dart';
import 'collection_validators.dart';
import 'my_collections_controller.dart';
import 'widgets/single_field_dialog.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(myCollectionsControllerProvider);
    final controller = ref.read(myCollectionsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes collections'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Rejoindre'),
            onPressed: () => _openDialog(
              context,
              SingleFieldDialog(
                title: 'Rejoindre une collection',
                label: 'Code d\'invitation',
                submitLabel: 'Rejoindre',
                validator: CollectionValidators.inviteCode,
                onSubmit: controller.join,
                errorMessage: joinErrorMessage,
                maxLength: CollectionValidators.inviteCodeLength,
                // Strip pasted spaces before the length limit truncates the code.
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        // A failed reload is already shown by the error state.
        onRefresh: () => ref
            .refresh(myCollectionsControllerProvider.future)
            .then<void>((_) {}, onError: (_) {}),
        child: collections.when(
          data: (list) => list.isEmpty
              ? const _Message(
                  'Crée une collection ou rejoins celle d\'un ami.',
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => _CollectionTile(list[i]),
                ),
          error: (error, _) => _Message(
            userMessage(error),
            action: TextButton(
              onPressed: collections.isLoading
                  ? null
                  : () => ref.invalidate(myCollectionsControllerProvider),
              child: const Text('Réessayer'),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouvelle collection',
        child: const Icon(Icons.add),
        onPressed: () => _openDialog(
          context,
          SingleFieldDialog(
            title: 'Nouvelle collection',
            label: 'Nom',
            submitLabel: 'Créer',
            validator: CollectionValidators.name,
            onSubmit: controller.create,
            maxLength: CollectionValidators.nameMaxLength,
          ),
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, Widget dialog) =>
      showDialog<void>(context: context, builder: (_) => dialog);
}

/// Scrollable so pull-to-refresh also works on the empty and error states.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(text, textAlign: TextAlign.center),
        if (action != null) Center(child: action),
      ],
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile(this.collection);

  final CollectionEntry collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(collection.name),
      subtitle: Text(
        '${collection.itemCount} titre(s) · ${collection.memberCount} membre(s)',
      ),
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Actions',
        onSelected: (action) => _run(context, ref, action),
        itemBuilder: (_) => [
          if (collection.inviteCode != null)
            const PopupMenuItem(
              value: _Action.copyCode,
              child: Text('Copier le code d\'invitation'),
            ),
          collection.isOwner
              ? const PopupMenuItem(
                  value: _Action.delete,
                  child: Text('Supprimer'),
                )
              : const PopupMenuItem(
                  value: _Action.leave,
                  child: Text('Quitter'),
                ),
        ],
      ),
    );
  }

  void _run(BuildContext context, WidgetRef ref, _Action action) {
    final controller = ref.read(myCollectionsControllerProvider.notifier);
    switch (action) {
      case _Action.copyCode:
        _copyCode(context);
      case _Action.delete:
        _confirmThen(
          context,
          'Supprimer « ${collection.name} » pour tous ses membres ?',
          () => controller.delete(collection.id),
        );
      case _Action.leave:
        _confirmThen(
          context,
          'Quitter « ${collection.name} » ?',
          () => controller.leave(collection.id),
        );
    }
  }

  Future<void> _copyCode(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: collection.inviteCode!));
    messenger.showSnackBar(const SnackBar(content: Text('Code copié.')));
  }

  Future<void> _confirmThen(
    BuildContext context,
    String question,
    Future<void> Function() mutation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await mutation();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userMessage(e))));
    }
  }
}

enum _Action { copyCode, delete, leave }
