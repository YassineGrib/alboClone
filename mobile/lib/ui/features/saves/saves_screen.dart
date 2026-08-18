import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/collection.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/domain/save_timeline.dart';
import 'package:later/domain/source_app.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_logo.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';
import 'package:later/ui/core/widgets/sync_chip.dart';
import 'package:later/ui/features/collections/collections_screen.dart';
import 'package:later/ui/features/saves/save_filter_sheet.dart';
import 'package:later/ui/features/settings/settings_screen.dart';

class SavesScreen extends ConsumerStatefulWidget {
  const SavesScreen({super.key});

  @override
  ConsumerState<SavesScreen> createState() => _SavesScreenState();
}

class _SavesScreenState extends ConsumerState<SavesScreen> with WidgetsBindingObserver {
  final _url = TextEditingController();
  final _search = TextEditingController();
  final _urlFocus = FocusNode();
  String? _fieldError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      final items = ref.read(savesProvider).asData?.value ?? [];
      final waiting = items.any(
        (item) => item.syncStatus == SyncStatus.synced && item.contentStatus == ContentStatus.pending,
      );
      if (waiting) {
        syncLater(ref);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _url.dispose();
    _search.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncLater(ref);
    }
  }

  String? get _activeCollectionId {
    final scope = ref.read(saveFilterProvider).collection;
    return scope.kind == CollectionScopeKind.one ? scope.id : null;
  }

  Future<void> _add() async {
    setState(() => _fieldError = null);
    try {
      await ref.read(saveRepositoryProvider).addUrl(
            _url.text,
            collectionId: _activeCollectionId,
          );
      _url.clear();
      _urlFocus.unfocus();
    } on FormatException catch (error) {
      setState(() => _fieldError = error.message);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        ref.read(authTokenProvider.notifier).setToken(null);
      }
    }
  }

  Future<void> _move(SaveItem item) async {
    final folders = ref.read(collectionsProvider).asData?.value ?? [];
    final picked = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Move to folder', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              ListTile(
                leading: const Icon(Icons.label_off_outlined, size: 20),
                title: const Text('Unfiled'),
                trailing: item.collectionId == null ? const Icon(Icons.check, size: 18) : null,
                onTap: () => Navigator.of(context).pop(''),
              ),
              ...folders.map(
                (folder) => ListTile(
                  leading: const Icon(Icons.folder_outlined, size: 20),
                  title: Text(folder.name),
                  selected: item.collectionId == folder.id,
                  trailing: item.collectionId == folder.id ? const Icon(Icons.check, size: 18) : null,
                  onTap: () => Navigator.of(context).pop(folder.id),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    await ref.read(saveRepositoryProvider).moveToCollection(
          item,
          picked.isEmpty ? null : picked,
        );
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const SaveFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saves = ref.watch(visibleSavesProvider);
    final folders = ref.watch(collectionsProvider).asData?.value ?? <CollectionItem>[];
    final filter = ref.watch(saveFilterProvider);
    final theme = Theme.of(context);
    final allCount = ref.watch(savesProvider).asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const LaterLogo.mark(height: 28),
        actions: [
          IconButton(
            tooltip: 'Folders',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CollectionsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _url,
                              focusNode: _urlFocus,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.go,
                              decoration: InputDecoration(
                                hintText: 'Paste a link to save...',
                                prefixIcon: Icon(
                                  Icons.link_rounded,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                errorText: _fieldError,
                              ),
                              onSubmitted: (_) => _add(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _add,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Search titles or URLs...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                suffixIcon: filter.query.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _search.clear();
                                          ref.read(saveFilterProvider.notifier).setQuery('');
                                        },
                                      ),
                              ),
                              onChanged: (value) => ref.read(saveFilterProvider.notifier).setQuery(value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Badge(
                            isLabelVisible: filter.isConstrained,
                            smallSize: 8,
                            child: IconButton(
                              tooltip: 'Filters',
                              onPressed: _openFilters,
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                foregroundColor: theme.colorScheme.onSurface,
                                shape: const RoundedRectangleBorder(borderRadius: LaterTheme.radius),
                                side: BorderSide(color: theme.dividerColor),
                                minimumSize: const Size(52, 52),
                              ),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: saves.when(
                    data: (items) {
                      if (allCount == 0) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.bookmark_add_outlined,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your library is empty',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Paste a link above or share web pages directly to Later from any app.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 28,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No matching links',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nothing matches those search filters.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    _search.clear();
                                    ref.read(saveFilterProvider.notifier).clearAdvanced();
                                  },
                                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                                  label: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => syncLater(ref),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          slivers: [
                            for (final group in SaveTimeline.group(items, now: DateTime.now())) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        group.label.toUpperCase(),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Divider(
                                          height: 1,
                                          color: theme.dividerColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = group.items[index];
                                    return Column(
                                      children: [
                                        _saveTile(item, folders, theme),
                                        if (index != group.items.length - 1)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 80, right: 16),
                                            child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
                                          ),
                                      ],
                                    );
                                  },
                                  childCount: group.items.length,
                                ),
                              ),
                            ],
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 24),
                            ),
                          ],
                        ),
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

  Widget _saveTile(SaveItem item, List<CollectionItem> folders, ThemeData theme) {
    String? folderName;
    if (item.collectionId != null) {
      for (final folder in folders) {
        if (folder.id == item.collectionId) {
          folderName = folder.name;
          break;
        }
      }
    }
    final sourceAppId = SourceApp.idFor(item.url);
    final sourceLabel = SourceApp.label(sourceAppId);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(saveRepositoryProvider).delete(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: LaterColors.chipFailedBg,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: LaterColors.chipFailedFg, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: LaterColors.chipFailedFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onLongPress: () => _move(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: item.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (folderName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  folderName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            sourceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SyncChip(status: item.syncStatus),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.colorScheme.secondary),
                    onSelected: (value) {
                      if (value == 'move') {
                        _move(item);
                      } else if (value == 'retry') {
                        ref.read(saveRepositoryProvider).retry(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.drive_file_move_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Move to folder'),
                          ],
                        ),
                      ),
                      if (item.syncStatus == SyncStatus.syncFailed)
                        const PopupMenuItem(
                          value: 'retry',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Retry sync'),
                            ],
                          ),
                        ),
                    ],
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackBg = theme.colorScheme.surfaceContainerHighest;
    final fallbackFg = theme.colorScheme.secondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url == null
            ? Container(
                color: fallbackBg,
                child: Icon(
                  Icons.language_rounded,
                  size: 24,
                  color: fallbackFg,
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: fallbackBg,
                  child: Icon(
                    Icons.language_rounded,
                    size: 24,
                    color: fallbackFg,
                  ),
                ),
              ),
      ),
    );
  }
}
