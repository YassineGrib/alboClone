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
}
