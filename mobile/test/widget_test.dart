import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/core/theme/later_theme.dart';

void main() {
  testWidgets('dark theme paints the spec canvas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        darkTheme: LaterTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: Text('Later')),
      ),
    );

    final scaffold = tester.widget<Material>(find.byType(Material).first);
    expect(scaffold.color, LaterColors.darkCanvas);
  });
}
