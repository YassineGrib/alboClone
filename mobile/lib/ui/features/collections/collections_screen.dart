import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/collection.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final _name = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _fieldError = null);
    try {
      await ref.read(collectionRepositoryProvider).create(_name.text);
      _name.clear();
    } on FormatException catch (error) {
      setState(() => _fieldError = error.message);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        ref.read(authTokenProvider.notifier).setToken(null);
      }
    }
  }

  Future<void> _rename(CollectionItem item) async {
    final controller = TextEditingController(text: item.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (next == null) {
      return;
    }
    try {
      await ref.read(collectionRepositoryProvider).rename(item, next);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(CollectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${item.name}?'),
          content: const Text('Saves stay. They just leave this folder.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final filter = ref.read(saveFilterProvider);
    await ref.read(collectionRepositoryProvider).delete(item);
    if (filter.collection.id == item.id) {
      ref.read(saveFilterProvider.notifier).setCollection(const CollectionScope.all());
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(collectionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: Column(
              children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'New folder',
                      errorText: _fieldError,
                    ),
                    onSubmitted: (_) => _create(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _create, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: folders.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Folders group saves you want together.',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _rename(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _delete(item),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    ),
    ],
  ),
);
  }
}
