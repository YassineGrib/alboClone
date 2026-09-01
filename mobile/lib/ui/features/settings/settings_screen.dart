import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/api_url.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/l10n/app_localizations.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/bouncy_tap.dart';
import 'package:later/ui/core/widgets/later_form.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';
import 'package:later/ui/core/widgets/sync_chip.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _api;
  late final TabController _tabController;
  String? _apiError;
  bool _isTestingConnection = false;
  bool? _connectionSuccess;
  String? _connectionMessage;
  bool _isSyncingAll = false;
  bool _showServerConfig = false;
  int _settingsTapCount = 0;
  bool _isExporting = false;
  bool _isImporting = false;

  void _onTitleTap() {
    setState(() {
      _settingsTapCount++;
      if (_settingsTapCount >= 3) {
        _showServerConfig = true;
      }
    });
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(backupRepositoryProvider).exportBackupFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importRestore() async {
    setState(() => _isImporting = true);
    try {
      final count = await ref.read(backupRepositoryProvider).importAndRestoreFile();
      if (mounted && count != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully restored $count items and collections!'),
            backgroundColor: LaterColors.chipSyncedFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _api = TextEditingController(text: ref.read(apiBaseUrlProvider));
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _api.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onApiChanged(String value) {
    final trimmed = value.trim();
    if (!isLaterApiUrl(trimmed)) {
      setState(() => _apiError = 'Use an http URL with a host, like http://192.168.1.4:8080');
      return;
    }
    setState(() {
      _apiError = null;
      _connectionSuccess = null;
      _connectionMessage = null;
    });
    ref.read(apiBaseUrlProvider.notifier).setUrl(trimmed);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = null;
      _connectionMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final ok = await client.checkConnection();
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = ok;
          _connectionMessage = ok ? 'Server is online and reachable! (200 OK)' : 'Unexpected response from server';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = false;
          _connectionMessage = e.toString();
        });
      }
    }
  }

  Future<void> _syncAllNow() async {
    setState(() => _isSyncingAll = true);
    try {
      await ref.read(collectionRepositoryProvider).sync();
      await ref.read(saveRepositoryProvider).sync();
      if (mounted) {
        setState(() => _isSyncingAll = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync complete! All pending links synced with server.'),
            backgroundColor: LaterColors.chipSyncedFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncingAll = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: LaterColors.chipFailedFg,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authTokenProvider.notifier).setToken(null);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account & Data?'),
        content: const Text(
          'This will permanently delete your account, authentication tokens, and all saved links and folders from our servers. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LaterColors.chipFailedFg),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authRepositoryProvider).deleteAccount();
        ref.read(authTokenProvider.notifier).setToken(null);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account and all data deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTitleTap,
          child: Text(l10n.get('settings')),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.tune_outlined), text: l10n.get('general')),
            Tab(icon: const Icon(Icons.auto_awesome_outlined), text: l10n.get('geminiAi')),
            Tab(icon: const Icon(Icons.help_outline_rounded), text: l10n.get('guide')),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(context, theme),
                _buildAiTab(context, theme),
                _buildGuideTab(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, ThemeData theme) {
    final mode = ref.watch(themeModeProvider);
    final loggedIn = ref.watch(authTokenProvider) != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final saves = ref.watch(savesProvider).asData?.value ?? [];
    final l10n = context.l10n;

    final syncedCount = saves.where((s) => s.syncStatus == SyncStatus.synced).length;
    final pendingCount = saves.where((s) => s.syncStatus == SyncStatus.pendingSync).length;
    final failedCount = saves.where((s) => s.syncStatus == SyncStatus.syncFailed).length;
    final failedItem = saves.where((s) => s.syncStatus == SyncStatus.syncFailed && s.syncError != null).firstOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildSettingsSectionCard(
          context: context,
          icon: Icons.backup_outlined,
          title: l10n.get('backupAndRestore'),
          subtitle: l10n.get('backupAndRestoreSub'),
          iconColor: Colors.blue.shade700,
          children: [
            Row(
              children: [
                Expanded(
                  child: BouncyTap(
                    onTap: _isExporting ? null : _exportBackup,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _exportBackup,
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(
                        _isExporting ? l10n.get('exporting') : l10n.get('exportBackup'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyTap(
                    onTap: _isImporting ? null : _importRestore,
                    child: FilledButton.icon(
                      onPressed: _isImporting ? null : _importRestore,
                      icon: _isImporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(
                        _isImporting ? l10n.get('restoring') : l10n.get('restoreFile'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        if (_showServerConfig) ...[
          _buildSettingsSectionCard(
            context: context,
            icon: Icons.dns_outlined,
            title: l10n.get('serverConnection'),
            subtitle: l10n.get('serverConnectionSub'),
            iconColor: Colors.teal.shade700,
            children: [
              LaterLabel(l10n.get('apiUrl')),
              TextField(
                controller: _api,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'https://later-dz.site',
                  prefixIcon: const LaterInputIcon(Icons.link_outlined),
                  errorText: _apiError,
                  errorMaxLines: 3,
                ),
                onChanged: _onApiChanged,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sensors_rounded, size: 18),
                      label: Text(_isTestingConnection ? l10n.get('testing') : l10n.get('testConnection')),
                    ),
                  ),
                ],
              ),
              if (_connectionMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _connectionSuccess == true ? LaterColors.chipSyncedBg : LaterColors.chipFailedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _connectionSuccess == true ? LaterColors.chipSyncedFg.withValues(alpha: 0.3) : LaterColors.chipFailedFg.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _connectionSuccess == true ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        size: 18,
                        color: _connectionSuccess == true ? LaterColors.chipSyncedFg : LaterColors.chipFailedFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectionMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _connectionSuccess == true ? LaterColors.chipSyncedFg : LaterColors.chipFailedFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],

        _buildSettingsSectionCard(
          context: context,
          icon: Icons.sync_rounded,
          title: l10n.get('syncStatusTitle'),
          subtitle: l10n.get('syncStatusSub'),
          iconColor: Colors.green.shade700,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _syncBadgeColumn(l10n.get('synced'), syncedCount, LaterColors.chipSyncedBg, LaterColors.chipSyncedFg),
                _syncBadgeColumn(l10n.get('pending'), pendingCount, LaterColors.chipPendingBg, LaterColors.chipPendingFg),
                _syncBadgeColumn(l10n.get('failed'), failedCount, LaterColors.chipFailedBg, LaterColors.chipFailedFg),
              ],
            ),
            if (failedItem?.syncError != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                'Last error: ${failedItem!.syncError}',
                style: const TextStyle(fontSize: 12, color: LaterColors.chipFailedFg, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSyncingAll ? null : _syncAllNow,
                icon: _isSyncingAll
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_isSyncingAll ? l10n.get('syncing') : l10n.get('syncEverythingNow')),
              ),
            ),
          ],
        ),

        _buildSettingsSectionCard(
          context: context,
          icon: Icons.palette_outlined,
          title: l10n.get('appearance'),
          subtitle: l10n.get('appearanceSub'),
          iconColor: Colors.amber.shade800,
          children: [
            SegmentedButton<ThemeMode>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.get('system')),
                  icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                  tooltip: 'Match the phone',
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.get('light')),
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.get('dark')),
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(themeModeProvider.notifier).setMode(value.first);
                });
              },
            ),
          ],
        ),

        _buildSettingsSectionCard(
          context: context,
          icon: Icons.language_rounded,
          title: l10n.get('language'),
          subtitle: l10n.get('languageSub'),
          iconColor: Colors.indigo.shade700,
          children: [
            SegmentedButton<String>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 'system',
                  label: Text(l10n.get('auto')),
                  tooltip: 'Match phone language',
                ),
                const ButtonSegment(
                  value: 'en',
                  label: Text('EN'),
                ),
                const ButtonSegment(
                  value: 'ar',
                  label: Text('عربي'),
                ),
                const ButtonSegment(
                  value: 'fr',
                  label: Text('FR'),
                ),
              ],
              selected: {ref.watch(appLanguageProvider)},
              onSelectionChanged: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(appLanguageProvider.notifier).setLanguage(value.first);
                });
              },
            ),
          ],
        ),

        _buildSettingsSectionCard(
          context: context,
          icon: Icons.cleaning_services_rounded,
          title: l10n.get('cacheAndStorage'),
          subtitle: l10n.get('cacheSub'),
          iconColor: Colors.purple.shade700,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App image cache cleared successfully!'),
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: Text(l10n.get('clearImageCache')),
              ),
            ),
          ],
        ),

        _buildSettingsSectionCard(
          context: context,
          icon: Icons.shield_outlined,
          title: l10n.get('legalAndPrivacy'),
          subtitle: l10n.get('legalSub'),
          iconColor: Colors.blueGrey.shade800,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined, size: 20),
              title: Text(l10n.get('privacyPolicy'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('https://later-dz.site/privacy', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _openExternalUrl('https://later-dz.site/privacy'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, size: 20),
              title: Text(l10n.get('termsOfService'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('https://later-dz.site/terms', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _openExternalUrl('https://later-dz.site/terms'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded, size: 20),
              title: Text(l10n.get('dataSafety'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(l10n.get('dataSafetySub'), style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),

        if (loggedIn) ...[
          _buildSettingsSectionCard(
            context: context,
            icon: Icons.person_outline,
            title: l10n.get('sessionAndAccount'),
            subtitle: l10n.get('sessionSub'),
            iconColor: Colors.red.shade700,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_outlined, size: 18),
                      label: Text(l10n.get('logOut')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LaterColors.chipFailedFg,
                        side: const BorderSide(color: LaterColors.chipFailedFg),
                      ),
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined, size: 18),
                      label: Text(l10n.get('deleteAccountAndData')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _syncBadgeColumn(String label, int count, Color bg, Color fg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: fg),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAiTab(BuildContext context, ThemeData theme) {
    final aiEnabled = ref.watch(aiEnabledProvider);
    final aiSummaries = ref.watch(aiSummarizationProvider);
    final aiCategories = ref.watch(aiCategorizationProvider);
    final aiTags = ref.watch(aiTagsEnabledProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
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
                    const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gemini AI Assistant',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch.adaptive(
                      value: aiEnabled,
                      onChanged: (val) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(aiEnabledProvider.notifier).set(val);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Powered by Google Gemini 1.5 Flash to automatically summarize, categorize, and tag saved links.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const LaterSectionTitle(icon: Icons.checklist_rounded, title: 'AI Services & Features'),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: const Text('AI Link Summarization'),
          subtitle: const Text('Generates a 1-2 sentence overview of saved web content'),
          secondary: const Icon(Icons.short_text_rounded),
          value: aiEnabled && aiSummaries,
          onChanged: aiEnabled
              ? (val) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(aiSummarizationProvider.notifier).set(val);
                  });
                }
              : null,
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          title: const Text('Smart Content Categorization'),
          subtitle: const Text('Classifies links as Recipe, Video, Article, Product, Place'),
          secondary: const Icon(Icons.category_outlined),
          value: aiEnabled && aiCategories,
          onChanged: aiEnabled
              ? (val) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(aiCategorizationProvider.notifier).set(val);
                  });
                }
              : null,
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          title: const Text('Auto-Tagging'),
          subtitle: const Text('Extracts smart keywords to organize saves'),
          secondary: const Icon(Icons.sell_outlined),
          value: aiEnabled && aiTags,
          onChanged: aiEnabled
              ? (val) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(aiTagsEnabledProvider.notifier).set(val);
                  });
                }
              : null,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI features require a valid GEMINI_API_KEY in the Laravel server environment.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const LaterSectionTitle(icon: Icons.help_outline_rounded, title: 'How to use this app'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save links effortlessly',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Share links directly from apps like TikTok, Chrome, or Instagram via system Share menu.\n'
                  '• Or paste any URL in the home screen input field.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sync status badges',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    SyncChip(status: SyncStatus.synced),
                    SizedBox(width: 8),
                    Expanded(child: Text('S = Synced with server', style: TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    SyncChip(status: SyncStatus.pendingSync),
                    SizedBox(width: 8),
                    Expanded(child: Text('P = Pending sync (saved locally)', style: TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    SyncChip(status: SyncStatus.syncFailed),
                    SizedBox(width: 8),
                    Expanded(child: Text('F = Failed sync (tap ... on card to retry)', style: TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(welcomeSeenProvider.notifier).resetWelcome();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.slideshow_rounded, size: 18),
                    label: const Text('Replay Onboarding Carousel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
