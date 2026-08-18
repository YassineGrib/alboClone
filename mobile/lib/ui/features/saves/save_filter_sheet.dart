import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/domain/source_app.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';

class SaveFilterSheet extends ConsumerWidget {
  const SaveFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(saveFilterProvider);
    final folders = ref.watch(collectionsProvider).asData?.value ?? [];
    final saves = ref.watch(savesProvider).asData?.value ?? [];
    final apps = {
      for (final item in saves) SourceApp.idFor(item.url),
    }.toList()
      ..sort((a, b) => SourceApp.label(a).compareTo(SourceApp.label(b)));
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: filter.isConstrained
                      ? () => ref.read(saveFilterProvider.notifier).clearAdvanced()
                      : null,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Section(
              title: 'When',
              children: [
                _Chip(
                  label: 'Any time',
                  selected: filter.when == SaveWhen.any,
                  onTap: () => ref.read(saveFilterProvider.notifier).setWhen(SaveWhen.any),
                ),
                _Chip(
                  label: 'Today',
                  selected: filter.when == SaveWhen.today,
                  onTap: () => ref.read(saveFilterProvider.notifier).setWhen(SaveWhen.today),
                ),
                _Chip(
                  label: 'Yesterday',
                  selected: filter.when == SaveWhen.yesterday,
                  onTap: () => ref.read(saveFilterProvider.notifier).setWhen(SaveWhen.yesterday),
                ),
                _Chip(
                  label: 'Last 7 days',
                  selected: filter.when == SaveWhen.last7,
                  onTap: () => ref.read(saveFilterProvider.notifier).setWhen(SaveWhen.last7),
                ),
                _Chip(
                  label: 'Last 30 days',
                  selected: filter.when == SaveWhen.last30,
                  onTap: () => ref.read(saveFilterProvider.notifier).setWhen(SaveWhen.last30),
                ),
              ],
            ),
            _Section(
              title: 'App',
              children: [
                _Chip(
                  label: 'Any app',
                  selected: filter.appId == null,
                  onTap: () => ref.read(saveFilterProvider.notifier).setApp(null),
                ),
                for (final id in apps)
                  _Chip(
                    label: SourceApp.label(id),
                    selected: filter.appId == id,
                    onTap: () => ref.read(saveFilterProvider.notifier).setApp(id),
                  ),
              ],
            ),
            _Section(
              title: 'Folder',
              children: [
                _Chip(
                  label: 'All',
                  selected: filter.collection.kind == CollectionScopeKind.all,
                  onTap: () => ref.read(saveFilterProvider.notifier).setCollection(
                        const CollectionScope.all(),
                      ),
                ),
                _Chip(
                  label: 'Unfiled',
                  selected: filter.collection.kind == CollectionScopeKind.unfiled,
                  onTap: () => ref.read(saveFilterProvider.notifier).setCollection(
                        const CollectionScope.unfiled(),
                      ),
                ),
                for (final folder in folders)
                  _Chip(
                    label: folder.name,
                    selected: filter.collection.id == folder.id,
                    onTap: () => ref.read(saveFilterProvider.notifier).setCollection(
                          CollectionScope.one(folder.id),
                        ),
                  ),
              ],
            ),
            _Section(
              title: 'Status',
              children: [
                _Chip(
                  label: 'Any',
                  selected: filter.status == null,
                  onTap: () => ref.read(saveFilterProvider.notifier).setStatus(null),
                ),
                _Chip(
                  label: 'Ready',
                  selected: filter.status == ContentStatus.ready,
                  onTap: () => ref.read(saveFilterProvider.notifier).setStatus(ContentStatus.ready),
                ),
                _Chip(
                  label: 'Pending',
                  selected: filter.status == ContentStatus.pending,
                  onTap: () => ref.read(saveFilterProvider.notifier).setStatus(ContentStatus.pending),
                ),
                _Chip(
                  label: 'Failed',
                  selected: filter.status == ContentStatus.failed,
                  onTap: () => ref.read(saveFilterProvider.notifier).setStatus(ContentStatus.failed),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(borderRadius: LaterTheme.radius),
    );
  }
}
