import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/domain/api_url.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_form.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _api;
  String? _apiError;

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
    setState(() => _apiError = null);
    ref.read(apiBaseUrlProvider.notifier).setUrl(trimmed);
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
    final mode = ref.watch(themeModeProvider);
    final loggedIn = ref.watch(authTokenProvider) != null;
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 32 + bottom),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
          const LaterSectionTitle(icon: Icons.dns_outlined, title: 'Laravel API'),
          const SizedBox(height: 6),
          Text(
            'The phone talks to this URL. Change it if login cannot reach the Mac.',
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
              hintText: 'http://192.168.1.4:8080',
              prefixIcon: const LaterInputIcon(Icons.link_outlined),
              errorText: _apiError,
              errorMaxLines: 3,
            ),
            onChanged: _onApiChanged,
          ),
          const LaterHelper(
            'Simulator: http://127.0.0.1:8080. Phone: your Mac LAN IP on port 8080.',
          ),
          const SizedBox(height: 36),
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
              ref.read(themeModeProvider.notifier).setMode(value.first);
            },
          ),
          if (loggedIn) ...[
            const SizedBox(height: 48),
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
      ),
    ),
    ],
  ),
);
  }
}
