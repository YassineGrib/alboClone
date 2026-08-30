import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/auth/login_screen.dart';
import 'package:later/ui/features/saves/saves_screen.dart';
import 'package:later/ui/features/saves/share_listener.dart';
import 'package:later/ui/features/welcome/welcome_screen.dart';

class LaterApp extends ConsumerWidget {
  const LaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final token = ref.watch(authTokenProvider);
    final lang = ref.watch(appLanguageProvider);
    final hasSeenWelcome = ref.watch(welcomeSeenProvider);
    final locale = lang == 'system' ? null : Locale(lang);

    final Widget homeWidget;
    if (!hasSeenWelcome) {
      homeWidget = const WelcomeScreen();
    } else if (token == null) {
      homeWidget = const LoginScreen();
    } else {
      homeWidget = const SavesScreen();
    }

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: LaterTheme.light(),
      darkTheme: LaterTheme.dark(),
      themeMode: mode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: ShareListener(child: child ?? const SizedBox.shrink()),
        );
      },
      home: homeWidget,
    );
  }
}
