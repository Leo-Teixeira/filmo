import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../domain/collection_entry.dart';
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
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => SingleFieldDialog(
                title: 'Rejoindre une collection',
                label: 'Code d\'invitation',
                submitLabel: 'Rejoindre',
                validator: CollectionValidators.inviteCode,
                onSubmit: controller.join,
                errorMessage: CollectionValidators.joinError,
              ),
            ),
          ),
        ],
      ),
      body: collections.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('Crée une collection ou rejoins celle d\'un ami.'),
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _CollectionTile(list[i]),
              ),
        error: (error, _) => Center(child: Text(userMessage(error))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouvelle collection',
        child: const Icon(Icons.add),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => SingleFieldDialog(
            title: 'Nouvelle collection',
            label: 'Nom',
            submitLabel: 'Créer',
            validator: CollectionValidators.name,
            onSubmit: controller.create,
          ),
        ),
      ),
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile(this.collection);

  final CollectionEntry collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = collection.inviteCode;
    return ListTile(
      title: Text(collection.name),
      subtitle: Text(
        '${collection.itemCount} titre(s) · ${collection.memberCount} membre(s)'
        '${code != null ? ' · code $code' : ''}',
      ),
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Actions',
        onSelected: (action) => _run(context, ref, action),
        itemBuilder: (_) => [
          if (code != null)
            const PopupMenuItem(
              value: _Action.copyCode,
              child: Text('Copier le code'),
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

  Future<void> _run(BuildContext context, WidgetRef ref, _Action action) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(myCollectionsControllerProvider.notifier);
    final (
      String? question,
      Future<void> Function() mutation,
    ) = switch (action) {
      _Action.copyCode => (
        null,
        () => Clipboard.setData(ClipboardData(text: collection.inviteCode!)),
      ),
      _Action.delete => (
        'Supprimer « ${collection.name} » pour tous ses membres ?',
        () => controller.delete(collection.id),
      ),
      _Action.leave => (
        'Quitter « ${collection.name} » ?',
        () => controller.leave(collection.id),
      ),
    };
    if (question != null && !await _confirm(context, question)) return;
    try {
      await mutation();
      if (action == _Action.copyCode) {
        messenger.showSnackBar(const SnackBar(content: Text('Code copié.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userMessage(e))));
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
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
      ) ??
      false;
}

enum _Action { copyCode, delete, leave }
