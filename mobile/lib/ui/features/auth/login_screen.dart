import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'you@local.test');
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  bool _isRegistering = false;
  String? _error;
  bool _busy = false;
  bool _hidePassword = true;
  int _logoTapCount = 0;
  bool _showServer = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _toggleMode(bool registering) {
    if (_isRegistering == registering) return;
    setState(() {
      _isRegistering = registering;
      _error = null;
      if (registering && _email.text == 'you@local.test') {
        _email.clear();
      } else if (!registering && _email.text.isEmpty) {
        _email.text = 'you@local.test';
      }
    });
  }

  void _onLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= 3) {
        _showServer = true;
      }
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (_isRegistering) {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Enter name, email and password.');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters.');
        return;
      }
    } else {
      if (email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Enter email and password.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isRegistering) {
        await ref.read(authRepositoryProvider).register(name, email, password);
      } else {
        await ref.read(authRepositoryProvider).login(email, password);
      }
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

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '365151770587-2tte83j70ceop2f22g8ssir855nhadqv.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() => _error = 'Could not obtain Google ID token.');
        return;
      }
      await ref.read(authRepositoryProvider).loginWithGoogle(idToken);
      final token = await ref.read(authRepositoryProvider).token();
      ref.read(authTokenProvider.notifier).setToken(token);
    } on ApiException catch (error) {
      final unreachable = error.message == "Couldn't reach the server.";
      setState(() {
        _error = unreachable
            ? "Couldn't reach the server. Check the API URL in Settings."
            : error.message;
      });
    } catch (error) {
      setState(() => _error = 'Google Sign-In failed: $error');
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
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onLogoTap,
                      child: const LaterLogo.wordmark(height: 52),
                    ),
                    const SizedBox(height: 8),
                    Text('Save a link. Find it again.', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 28),

                    // Toggle Segmented Control
                    SegmentedButton<bool>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Log in'),
                          icon: Icon(Icons.login_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Create account'),
                          icon: Icon(Icons.person_add_outlined, size: 18),
                        ),
                      ],
                      selected: {_isRegistering},
                      onSelectionChanged: (value) => _toggleMode(value.first),
                    ),
                    const SizedBox(height: 24),

                    if (_isRegistering) ...[
                      const LaterLabel('Full Name'),
                      TextField(
                        controller: _name,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Jane Doe',
                          prefixIcon: LaterInputIcon(Icons.person_outline),
                        ),
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    const LaterLabel('Email'),
                    TextField(
                      controller: _email,
                      focusNode: _emailFocus,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: _isRegistering ? 'jane@example.com' : 'you@local.test',
                        prefixIcon: const LaterInputIcon(Icons.mail_outline),
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
                      autofillHints: _isRegistering
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: _isRegistering ? 'At least 6 characters' : null,
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

                    if (!_isRegistering)
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
                                Text(_isRegistering ? 'Creating account...' : 'Signing in...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isRegistering ? Icons.person_add_outlined : Icons.login_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(_isRegistering ? 'Create account' : 'Log in'),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.g_mobiledata_rounded, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            'Sign in with Google',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    if (_showServer) ...[
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
