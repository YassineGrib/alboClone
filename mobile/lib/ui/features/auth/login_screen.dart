import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/widgets/later_form.dart';
import 'package:later/ui/core/widgets/later_logo.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';
import 'package:later/ui/features/settings/settings_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'you@local.test');
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _error;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).login(email, password);
      final token = await ref.read(authRepositoryProvider).token();
      ref.read(authTokenProvider.notifier).setToken(token);
    } on ApiException catch (error) {
      final unreachable = error.message == "Couldn't reach the server.";
      setState(() {
        _error = unreachable
            ? "Couldn't reach the server. Check the API URL in Settings."
            : error.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openServer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = ref.watch(apiBaseUrlProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          Positioned.fill(
            child: SafeArea(
              child: AutofillGroup(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottom),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const LaterLogo.wordmark(height: 56),
                  const SizedBox(height: 10),
                  Text('Save a link. Find it again.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 40),
                  const LaterLabel('Email'),
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'you@local.test',
                      prefixIcon: LaterInputIcon(Icons.mail_outline),
                    ),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 18),
                  const LaterLabel('Password'),
                  TextField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      prefixIcon: const LaterInputIcon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const LaterHelper('Local seed is you@local.test / password.'),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    LaterErrorNote(_error!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Signing in'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Log in'),
                            ],
                          ),
                  ),
                  const SizedBox(height: 36),
                  Material(
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: InkWell(
                      onTap: _openServer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            const LaterInputIcon(Icons.dns_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Server', style: theme.textTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    api,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
