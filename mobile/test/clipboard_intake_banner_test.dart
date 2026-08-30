import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/l10n/app_localizations.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/clipboard_intake_banner.dart';

void main() {
  testWidgets('ClipboardIntakeBanner renders URL and triggers add & dismiss callbacks', (tester) async {
    bool addTapped = false;
    bool dismissTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ClipboardIntakeBanner(
            url: 'https://youtube.com/watch?v=12345',
            onAdd: () => addTapped = true,
            onDismiss: () => dismissTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link in Clipboard'), findsOneWidget);
    expect(find.text('https://youtube.com/watch?v=12345'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(addTapped, isTrue);
    expect(dismissTapped, isFalse);
  });
}
