import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:later/ui/core/widgets/swipe_to_delete_tile.dart';
import 'package:later/ui/features/collections/collections_screen.dart';
import 'package:later/ui/features/saves/save_detail_screen.dart';
import 'package:later/ui/features/saves/save_filter_sheet.dart';
import 'package:later/ui/features/settings/settings_screen.dart';

class SavesScreen extends ConsumerStatefulWidget {
  const SavesScreen({super.key});

  @override
  ConsumerState<SavesScreen> createState() => _SavesScreenState();
}

class _SavesScreenState extends ConsumerState<SavesScreen> with WidgetsBindingObserver {
  final _url = TextEditingController();
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
      final aiEnabled = ref.read(aiEnabledProvider);
      await ref.read(saveRepositoryProvider).addUrl(
            _url.text,
            collectionId: _activeCollectionId,
            aiEnabled: aiEnabled,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
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
                      IconButton(
                        tooltip: 'Add link',
                        onPressed: _add,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: const RoundedRectangleBorder(borderRadius: LaterTheme.radius),
                          minimumSize: const Size(52, 52),
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                if (filter.isConstrained)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              filter.query.isNotEmpty
                                  ? 'Search: "${filter.query}"'
                                  : (filter.sort == SaveSort.importanceFirst ? 'Sorted: Important first' : 'Filters applied'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(saveFilterProvider.notifier).clearAdvanced(),
                            child: Text(
                              'Clear',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      floatingActionButton: Badge(
        isLabelVisible: filter.isConstrained,
        smallSize: 8,
        child: FloatingActionButton(
          heroTag: 'filter_fab',
          tooltip: 'Search & Filters',
          onPressed: _openFilters,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: const Icon(Icons.tune_rounded, size: 22),
        ),
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

    return SwipeToDeleteTile(
      itemKey: ValueKey(item.id),
      onDismissed: () => ref.read(saveRepositoryProvider).delete(item),
      onMove: () => _move(item),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SaveDetailScreen(
                item: item,
                folderName: folderName,
              ),
            ),
          );
        },
        onLongPress: () => _move(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: item.imageUrl, itemUrl: item.url),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.priority > 0) ...[
                          Icon(
                            item.priority == 2 ? Icons.star_rounded : Icons.bookmark_rounded,
                            size: 16,
                            color: item.priority == 2 ? Colors.amber.shade700 : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.aiSummary != null && item.aiSummary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.aiSummary!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.category != null && item.category!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text(
                                  item.category!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.itemUrl});

  final String? url;
  final String itemUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackBg = theme.colorScheme.surfaceContainerHighest;
    final fallbackFg = theme.colorScheme.secondary;

    final host = (Uri.tryParse(itemUrl)?.host ?? '').toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final faviconUrl = host.isNotEmpty ? 'https://www.google.com/s2/favicons?domain=$host&sz=128' : null;
    final effectiveUrl = (url != null && url!.isNotEmpty) ? url! : faviconUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: effectiveUrl == null
            ? Container(
                color: fallbackBg,
                child: Icon(
                  Icons.language_rounded,
                  size: 24,
                  color: fallbackFg,
                ),
              )
            : CachedNetworkImage(
                imageUrl: effectiveUrl,
                fit: BoxFit.cover,
                memCacheWidth: 156,
                memCacheHeight: 156,
                placeholder: (context, url) => Container(
                  color: fallbackBg,
                  child: const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
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
