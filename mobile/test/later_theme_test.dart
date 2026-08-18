import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/core/theme/later_theme.dart';

void main() {
  test('light canvas is warm off-white not pure white', () {
    final theme = LaterTheme.light();
    expect(theme.scaffoldBackgroundColor, LaterColors.lightCanvas);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
  });

  test('dark canvas is off-black not pure black', () {
    final theme = LaterTheme.dark();
    expect(theme.scaffoldBackgroundColor, LaterColors.darkCanvas);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.black));
  });
}
