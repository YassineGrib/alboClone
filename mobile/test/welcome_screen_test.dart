import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/welcome/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('WelcomeScreen renders 3-slide onboarding carousel and navigates', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: LaterTheme.light(),
          home: const WelcomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Slide 1: Share From Any App
    expect(find.text('Share From Any App'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next -> Slide 2: AI Summaries & Tags
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('AI Summaries & Tags'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next -> Slide 3: Save Now, Read Calmly
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Save Now, Read Calmly'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
  });
}
