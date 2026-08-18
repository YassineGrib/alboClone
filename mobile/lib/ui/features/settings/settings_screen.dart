import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/api_url.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_form.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';
import 'package:later/ui/core/widgets/sync_chip.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _api;
  String? _apiError;
  bool _isTestingConnection = false;
  bool? _connectionSuccess;
  String? _connectionMessage;
  bool _isSyncingAll = false;

  @override
  void initState() {
    super.initState();
    _api = TextEditingController(text: ref.read(apiBaseUrlProvider));
  }

  @override
  void dispose() {
    _api.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.tune_outlined), text: 'General'),
              Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Gemini AI'),
              Tab(icon: Icon(Icons.help_outline_rounded), text: 'Guide'),
            ],
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: LaterMarkPattern()),
            Positioned.fill(
              child: TabBarView(
                children: [
                  _buildGeneralTab(context, theme),
                  _buildAiTab(context, theme),
                  _buildGuideTab(context, theme),
                ],
              ),
            ),
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

    final syncedCount = saves.where((s) => s.syncStatus == SyncStatus.synced).length;
    final pendingCount = saves.where((s) => s.syncStatus == SyncStatus.pendingSync).length;
    final failedCount = saves.where((s) => s.syncStatus == SyncStatus.syncFailed).length;
    final failedItem = saves.where((s) => s.syncStatus == SyncStatus.syncFailed && s.syncError != null).firstOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const LaterSectionTitle(icon: Icons.dns_outlined, title: 'Server Connection'),
        const SizedBox(height: 6),
        Text(
          'The phone talks to this backend API URL.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const LaterLabel('API URL'),
        TextField(
          controller: _api,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'http://192.168.1.123:8080',
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
                label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
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
        const SizedBox(height: 28),
        const LaterSectionTitle(icon: Icons.sync_rounded, title: 'Sync Status & Diagnostics'),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _syncBadgeColumn('Synced', syncedCount, LaterColors.chipSyncedBg, LaterColors.chipSyncedFg),
                    _syncBadgeColumn('Pending', pendingCount, LaterColors.chipPendingBg, LaterColors.chipPendingFg),
                    _syncBadgeColumn('Failed', failedCount, LaterColors.chipFailedBg, LaterColors.chipFailedFg),
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
                    label: Text(_isSyncingAll ? 'Syncing...' : 'Sync Everything Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const LaterSectionTitle(icon: Icons.palette_outlined, title: 'Appearance'),
        const SizedBox(height: 6),
        Text('Follows the phone unless you pin Light or Dark.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        SegmentedButton<ThemeMode>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_outlined, size: 18),
              tooltip: 'Match the phone',
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined, size: 18),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(themeModeProvider.notifier).setMode(value.first);
            });
          },
        ),
        const SizedBox(height: 28),
        const LaterSectionTitle(icon: Icons.language_rounded, title: 'Language'),
        const SizedBox(height: 6),
        Text('Choose the interface display language.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 'system',
              label: Text('Auto'),
              tooltip: 'Match phone language',
            ),
            ButtonSegment(
              value: 'en',
              label: Text('EN'),
            ),
            ButtonSegment(
              value: 'ar',
              label: Text('عربي'),
            ),
            ButtonSegment(
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
        if (loggedIn) ...[
          const SizedBox(height: 36),
          const LaterSectionTitle(icon: Icons.person_outline, title: 'Session'),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: LaterColors.chipFailedFg,
              side: const BorderSide(color: LaterColors.chipFailedFg),
            ),
            onPressed: _logout,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_outlined, size: 18),
                SizedBox(width: 8),
                Text('Log out'),
              ],
            ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
