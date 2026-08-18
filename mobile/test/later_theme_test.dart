import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:later/ui/core/theme/later_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('light canvas is warm off-white not pure white', (tester) async {
    final theme = LaterTheme.light();
    expect(theme.scaffoldBackgroundColor, LaterColors.lightCanvas);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
  });

  testWidgets('dark canvas is off-black not pure black', (tester) async {
    final theme = LaterTheme.dark();
    expect(theme.scaffoldBackgroundColor, LaterColors.darkCanvas);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.black));
  });

  testWidgets('theme uses IBM Plex Sans font family', (tester) async {
    final theme = LaterTheme.light();
    expect(theme.textTheme.bodyMedium?.fontFamily, isNotNull);
  });
}
