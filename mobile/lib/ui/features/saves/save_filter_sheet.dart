import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';

class SaveFilterSheet extends ConsumerStatefulWidget {
  const SaveFilterSheet({super.key});

  @override
  ConsumerState<SaveFilterSheet> createState() => _SaveFilterSheetState();
}

class _SaveFilterSheetState extends ConsumerState<SaveFilterSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(saveFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String name) {
    return switch (name.toLowerCase()) {
      'video' => Icons.play_circle_outline_rounded,
      'tool' => Icons.construction_rounded,
      'post' => Icons.article_outlined,
      'article' => Icons.menu_book_rounded,
      'recipe' => Icons.restaurant_rounded,
      'workout' => Icons.fitness_center_rounded,
      'product' => Icons.shopping_bag_outlined,
      _ => Icons.folder_outlined,
    };
  }

  int _whenToSliderIndex(SaveWhen when) {
    return switch (when) {
      SaveWhen.any => 0,
      SaveWhen.last30 => 1,
      SaveWhen.last7 => 2,
      SaveWhen.yesterday => 3,
      SaveWhen.today => 4,
    };
  }

  SaveWhen _sliderIndexToWhen(int index) {
    return switch (index) {
      0 => SaveWhen.any,
      1 => SaveWhen.last30,
      2 => SaveWhen.last7,
      3 => SaveWhen.yesterday,
      4 => SaveWhen.today,
      _ => SaveWhen.any,
    };
  }

  String _whenLabel(SaveWhen when) {
    return switch (when) {
      SaveWhen.any => 'All Time',
      SaveWhen.last30 => 'Past 30 Days',
      SaveWhen.last7 => 'Past 7 Days',
      SaveWhen.yesterday => 'Yesterday',
      SaveWhen.today => 'Today Only',
    };
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(saveFilterProvider);
    final folders = ref.watch(collectionsProvider).asData?.value ?? [];
    final saves = ref.watch(savesProvider).asData?.value ?? [];
    final categories = {
      for (final item in saves)
        if (item.category != null && item.category!.trim().isNotEmpty) item.category!.trim(),
    }.toList()
      ..sort();
    final theme = Theme.of(context);

    final timeSliderValue = _whenToSliderIndex(filter.when).toDouble();

    // Unified Folders & Categories List
    final Set<String> existingFolderNames = {for (final f in folders) f.name.toLowerCase()};
    final List<_UnifiedFolderItem> unifiedFolders = [
      ...folders.map((f) => _UnifiedFolderItem(
            id: f.id,
            name: f.name,
            icon: _categoryIcon(f.name),
            isCollection: true,
          )),
      ...categories
          .where((cat) => !existingFolderNames.contains(cat.toLowerCase()))
          .map((cat) => _UnifiedFolderItem(
                id: cat,
                name: cat,
                icon: _categoryIcon(cat),
                isCollection: false,
              )),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search & Filter',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  if (filter.isConstrained)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: LaterColors.chipFailedFg,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(saveFilterProvider.notifier).clearAdvanced();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search title, URL, or AI summary...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(saveFilterProvider.notifier).setQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (text) {
                  ref.read(saveFilterProvider.notifier).setQuery(text);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // 2. Sort & Priority Switcher
              Row(
                children: [
                  Icon(Icons.swap_vert_rounded, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Order By',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SegmentedButton<SaveSort>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(
                    value: SaveSort.importanceFirst,
                    icon: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    label: Text('Important'),
                  ),
                  ButtonSegment(
                    value: SaveSort.newestFirst,
                    icon: Icon(Icons.access_time_rounded, size: 16),
                    label: Text('Newest'),
                  ),
                  ButtonSegment(
                    value: SaveSort.oldestFirst,
                    icon: Icon(Icons.history_rounded, size: 16),
                    label: Text('Oldest'),
                  ),
                ],
                selected: {filter.sort},
                onSelectionChanged: (val) {
                  ref.read(saveFilterProvider.notifier).setSort(val.first);
                },
              ),
              const SizedBox(height: 14),

              // Importance Quick Toggle Card
              Container(
                decoration: BoxDecoration(
                  color: filter.priorityFilter == PriorityFilter.importantOnly
                      ? Colors.amber.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filter.priorityFilter == PriorityFilter.importantOnly
                        ? Colors.amber.withValues(alpha: 0.5)
                        : theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  dense: true,
                  secondary: Icon(
                    Icons.star_rounded,
                    color: filter.priorityFilter == PriorityFilter.importantOnly
                        ? Colors.amber.shade700
                        : theme.colorScheme.secondary,
                    size: 22,
                  ),
                  title: Text(
                    'High Importance Only',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: filter.priorityFilter == PriorityFilter.importantOnly
                          ? Colors.amber.shade900
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Filter only items marked as important',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                  ),
                  value: filter.priorityFilter == PriorityFilter.importantOnly,
                  onChanged: (enabled) {
                    ref.read(saveFilterProvider.notifier).setPriorityFilter(
                          enabled ? PriorityFilter.importantOnly : PriorityFilter.all,
                        );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // 3. Timeframe Timeline Slider (Progress Line / Timeline Stepper)
              Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Timeline: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _whenLabel(filter.when),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: theme.dividerColor,
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9.0),
                        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3.5),
                        activeTickMarkColor: theme.colorScheme.onPrimary,
                        inactiveTickMarkColor: theme.colorScheme.secondary.withValues(alpha: 0.4),
                      ),
                      child: Slider(
                        value: timeSliderValue,
                        min: 0,
                        max: 4,
                        divisions: 4,
                        onChanged: (val) {
                          final when = _sliderIndexToWhen(val.round());
                          ref.read(saveFilterProvider.notifier).setWhen(when);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _timelineLabel('All', timeSliderValue == 0, theme),
                          _timelineLabel('30d', timeSliderValue == 1, theme),
                          _timelineLabel('7d', timeSliderValue == 2, theme),
                          _timelineLabel('Yesterday', timeSliderValue == 3, theme),
                          _timelineLabel('Today', timeSliderValue == 4, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Unified Folders & Smart Categories (دمج المجلدات والتصنيفات)
              Row(
                children: [
                  Icon(Icons.folder_copy_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Folders & Categories',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    icon: Icons.grid_view_rounded,
                    label: 'All',
                    selected: filter.collection.kind == CollectionScopeKind.all && filter.category == null,
                    onTap: () {
                      ref.read(saveFilterProvider.notifier).setCollection(const CollectionScope.all());
                      ref.read(saveFilterProvider.notifier).setCategory(null);
                    },
                  ),
                  _Chip(
                    icon: Icons.inbox_outlined,
                    label: 'Unfiled',
                    selected: filter.collection.kind == CollectionScopeKind.unfiled,
                    onTap: () {
                      ref.read(saveFilterProvider.notifier).setCollection(const CollectionScope.unfiled());
                      ref.read(saveFilterProvider.notifier).setCategory(null);
                    },
                  ),
                  for (final item in unifiedFolders)
                    _Chip(
                      icon: item.icon,
                      label: item.name,
                      selected: (item.isCollection && filter.collection.id == item.id) ||
                          (!item.isCollection && filter.category?.toLowerCase() == item.name.toLowerCase()),
                      onTap: () {
                        if (item.isCollection) {
                          if (filter.collection.id == item.id) {
                            ref.read(saveFilterProvider.notifier).setCollection(const CollectionScope.all());
                          } else {
                            ref.read(saveFilterProvider.notifier).setCollection(CollectionScope.one(item.id));
                            ref.read(saveFilterProvider.notifier).setCategory(null);
                          }
                        } else {
                          if (filter.category?.toLowerCase() == item.name.toLowerCase()) {
                            ref.read(saveFilterProvider.notifier).setCategory(null);
                          } else {
                            ref.read(saveFilterProvider.notifier).setCategory(item.name);
                            ref.read(saveFilterProvider.notifier).setCollection(const CollectionScope.all());
                          }
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Apply & Close Button
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Show Results',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _timelineLabel(String text, bool active, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10.5,
        fontWeight: active ? FontWeight.bold : FontWeight.w500,
        color: active ? theme.colorScheme.primary : theme.colorScheme.secondary,
      ),
    );
  }
}

class _UnifiedFolderItem {
  const _UnifiedFolderItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.isCollection,
  });

  final String id;
  final String name;
  final IconData icon;
  final bool isCollection;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.secondary,
            )
          : null,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.14),
      shape: const RoundedRectangleBorder(borderRadius: LaterTheme.radius),
    );
  }
}
