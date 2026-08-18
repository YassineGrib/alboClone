import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/auth/login_screen.dart';
import 'package:later/ui/features/saves/saves_screen.dart';
import 'package:later/ui/features/saves/share_listener.dart';

class LaterApp extends ConsumerWidget {
  const LaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final token = ref.watch(authTokenProvider);
    final lang = ref.watch(appLanguageProvider);
    final locale = lang == 'system' ? null : Locale(lang);

    return MaterialApp(
      title: 'Later',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: laterMessengerKey,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ],
      theme: LaterTheme.light(),
      darkTheme: LaterTheme.dark(),
      themeMode: mode,
      builder: (context, child) => ShareListener(child: child ?? const SizedBox.shrink()),
      home: token == null ? const LoginScreen() : const SavesScreen(),
    );
  }
}
