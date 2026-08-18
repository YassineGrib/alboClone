import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_logo.dart';

void main() {
  testWidgets('mark logo exposes the Later name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: const Scaffold(body: LaterLogo.mark()),
      ),
    );
    expect(find.bySemanticsLabel('Later'), findsOneWidget);
  });
}
