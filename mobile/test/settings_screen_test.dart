import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/repositories/auth_repository.dart';
import 'package:later/data/repositories/settings_repository.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('invalid API URL shows an error when server config is unlocked', (tester) async {
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

    // Tap title 3 times to unlock Server Connection
    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Server Connection'), findsOneWidget);

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

  testWidgets('shows Backup & Restore and hidden Server Connection on General tab', (tester) async {
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

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Restore File'), findsOneWidget);
    expect(find.text('Server Connection'), findsNothing);

    // Tap title 3 times to unlock Server Connection
    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Server Connection'), findsOneWidget);
    expect(find.text('Test Connection'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Language'),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('shows Delete Account button and dialog when logged in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({AuthRepository.tokenKey: 'test_token'});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    container.read(authTokenProvider.notifier).setToken('test_token');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: LaterTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account & Data'),
      300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Delete Account & Data'), findsOneWidget);

    await tester.ensureVisible(find.text('Delete Account & Data'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Account & Data'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account & Data?'), findsOneWidget);
    expect(find.textContaining('This will permanently delete your account'), findsOneWidget);
  });
}
