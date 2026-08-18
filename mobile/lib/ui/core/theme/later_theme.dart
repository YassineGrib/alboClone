import 'package:flutter/material.dart';

class LaterColors {
  static const lightCanvas = Color(0xFFF7F6F3);
  static const lightSurface = Color(0xFFFFFEFC);
  static const lightInk = Color(0xFF2F3437);
  static const lightMuted = Color(0xFF787774);
  static const lightLine = Color(0xFFEAEAEA);

  static const darkCanvas = Color(0xFF1C1C1A);
  static const darkSurface = Color(0xFF2A2A27);
  static const darkInk = Color(0xFFEDEDEC);
  static const darkMuted = Color(0xFF9B9A97);
  static const darkLine = Color(0xFF3A3A36);

  static const chipPendingBg = Color(0xFFFBF3DB);
  static const chipPendingFg = Color(0xFF956400);
  static const chipSyncedBg = Color(0xFFEDF3EC);
  static const chipSyncedFg = Color(0xFF346538);
  static const chipFailedBg = Color(0xFFFDEBEC);
  static const chipFailedFg = Color(0xFF9F2F2D);
}

class LaterTheme {
  static const radius = BorderRadius.all(Radius.circular(8));

  static ThemeData light() => _build(
        brightness: Brightness.light,
        canvas: LaterColors.lightCanvas,
        surface: LaterColors.lightSurface,
        ink: LaterColors.lightInk,
        muted: LaterColors.lightMuted,
        line: LaterColors.lightLine,
        primaryFill: LaterColors.lightInk,
        onPrimary: LaterColors.lightSurface,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        canvas: LaterColors.darkCanvas,
        surface: LaterColors.darkSurface,
        ink: LaterColors.darkInk,
        muted: LaterColors.darkMuted,
        line: LaterColors.darkLine,
        primaryFill: LaterColors.darkInk,
        onPrimary: LaterColors.darkCanvas,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
    required Color primaryFill,
    required Color onPrimary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primaryFill,
      onPrimary: onPrimary,
      secondary: muted,
      onSecondary: surface,
      error: LaterColors.chipFailedFg,
      onError: LaterColors.chipFailedBg,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      fontFamily: null,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted, fontSize: 16),
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: ink, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: LaterColors.chipFailedFg),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: LaterColors.chipFailedFg, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        floatingLabelStyle: TextStyle(color: muted, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: onPrimary,
          disabledBackgroundColor: ink.withValues(alpha: 0.18),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: line),
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: line)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return onPrimary;
            }
            return ink;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryFill;
            }
            return surface;
          }),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: onPrimary, fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        dragHandleColor: line,
      ),
      dividerColor: line,
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ink.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: ink, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: line),
        showCheckmark: false,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: ink, fontSize: 16, height: 1.4),
        bodySmall: TextStyle(color: muted, fontSize: 13, height: 1.4),
      ),
    );
  }
}
