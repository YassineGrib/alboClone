import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/repositories/settings_repository.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('invalid API URL shows an error and is not saved', (tester) async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.apiKey: 'http://127.0.0.1:8080',
    });
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: LaterTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not-a-url');
    await tester.pump();

    expect(find.textContaining('Use an http URL with a host'), findsOneWidget);
    expect(prefs.getString(SettingsRepository.apiKey), 'http://127.0.0.1:8080');
  });

  testWidgets('shows How to use section under Guide tab', (tester) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Guide tab
    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();

    expect(find.text('How to use this app'), findsOneWidget);
    expect(find.textContaining('Save links'), findsOneWidget);
    expect(find.textContaining('Sync status badges'), findsOneWidget);
  });

  testWidgets('shows Gemini AI settings under Gemini AI tab', (tester) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Gemini AI tab
    await tester.tap(find.text('Gemini AI'));
    await tester.pumpAndSettle();

    expect(find.text('Gemini AI Assistant'), findsOneWidget);
    expect(find.text('AI Link Summarization'), findsOneWidget);
    expect(find.text('Smart Content Categorization'), findsOneWidget);
  });

  testWidgets('shows Server Connection and Sync Status sections on General tab', (tester) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Server Connection'), findsOneWidget);
    expect(find.text('Test Connection'), findsOneWidget);
    expect(find.text('Sync Status & Diagnostics'), findsOneWidget);
    expect(find.text('Sync Everything Now'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Language'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Language'), findsOneWidget);
  });
}
