import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/domain/source_app.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';
import 'package:later/ui/core/widgets/sync_chip.dart';
import 'package:url_launcher/url_launcher.dart';

class SaveDetailScreen extends ConsumerStatefulWidget {
  const SaveDetailScreen({
    super.key,
    required this.item,
    this.folderName,
  });

  final SaveItem item;
  final String? folderName;

  @override
  ConsumerState<SaveDetailScreen> createState() => _SaveDetailScreenState();
}

class _SaveDetailScreenState extends ConsumerState<SaveDetailScreen> {
  late SaveItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _openLink() async {
    final uri = Uri.parse(_item.url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${_item.url}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch link: $e')),
        );
      }
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _item.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied to clipboard!')),
    );
  }

  Future<void> _setPriority(int priority) async {
    setState(() => _item = _item.copyWith(priority: priority));
    await ref.read(saveRepositoryProvider).setPriority(_item, priority);
  }

  Future<void> _move() async {
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
                title: Text(
                  'Move to folder',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ...folders.map(
                (folder) => ListTile(
                  leading: const Icon(Icons.folder_outlined, size: 20),
                  title: Text(folder.name),
                  selected: _item.collectionId == folder.id,
                  trailing: _item.collectionId == folder.id ? const Icon(Icons.check, size: 18) : null,
                  onTap: () => Navigator.of(context).pop(folder.id),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      await ref.read(saveRepositoryProvider).moveToCollection(_item, picked);
      setState(() {
        _item = _item.copyWith(collectionId: picked);
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete save?'),
        content: const Text('Are you sure you want to delete this saved link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LaterColors.chipFailedFg),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(saveRepositoryProvider).delete(_item);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month ${local.day}, ${local.year} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceAppId = SourceApp.idFor(_item.url);
    final sourceLabel = SourceApp.label(sourceAppId);
    final host = (Uri.tryParse(_item.url)?.host ?? '').toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final faviconUrl = host.isNotEmpty ? 'https://www.google.com/s2/favicons?domain=$host&sz=128' : null;
    final effectiveHeaderUrl = (_item.imageUrl != null && _item.imageUrl!.isNotEmpty) ? _item.imageUrl! : faviconUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Details'),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.copy_outlined, size: 20),
            onPressed: _copyUrl,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: _delete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLink,
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text(
          'Open Link',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
              children: [
                // Header Image Thumbnail
                if (effectiveHeaderUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: CachedNetworkImage(
                        imageUrl: effectiveHeaderUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title / Name of the Save
                Text(
                  _item.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Source & Category Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Badge
                    if (_item.category != null && _item.category!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              _item.category!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // App Source Chip
                    Chip(
                      avatar: const Icon(Icons.language_rounded, size: 16),
                      label: Text(sourceLabel),
                      visualDensity: VisualDensity.compact,
                    ),

                    // Sync Status Badge
                    SyncChip(status: _item.syncStatus),
                  ],
                ),

                const SizedBox(height: 16),

                // Refined Importance / Priority Widget UI
                _buildImportanceWidget(theme),

                const SizedBox(height: 16),

                // AI Summary Section (AI Summarize Display)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Gemini AI Summary',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (_item.aiSummary != null && _item.aiSummary!.isNotEmpty)
                              ? _item.aiSummary!
                              : 'AI summary is generating or will be processed upon server sync.',
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            fontStyle: (_item.aiSummary != null && _item.aiSummary!.isNotEmpty)
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Tags
                if (_item.aiTags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _item.aiTags
                        .map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Metadata Details Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.link_outlined),
                        title: const Text('URL'),
                        subtitle: Text(
                          _item.url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: _copyUrl,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Folder'),
                        subtitle: Text(widget.folderName ?? 'Global'),
                        trailing: TextButton(
                          onPressed: _move,
                          child: const Text('Change'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Date Saved'),
                        subtitle: Text(_formatDate(_item.createdAt)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceWidget(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _item.priority == 2
              ? Colors.amber.withValues(alpha: 0.7)
              : (_item.priority == 1 ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor),
          width: _item.priority > 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _item.priority == 2
                    ? Icons.star_rounded
                    : (_item.priority == 1 ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                color: _item.priority == 2
                    ? Colors.amber.shade700
                    : (_item.priority == 1 ? theme.colorScheme.primary : theme.colorScheme.secondary),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Importance / Priority',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_item.priority == 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'High Priority',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Normal'),
                  icon: Icon(Icons.radio_button_unchecked, size: 14),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Medium'),
                  icon: Icon(Icons.bookmark_outlined, size: 14),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('High'),
                  icon: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                ),
              ],
              selected: {_item.priority},
              onSelectionChanged: (val) => _setPriority(val.first),
            ),
          ),
        ],
      ),
    );
  }
}
