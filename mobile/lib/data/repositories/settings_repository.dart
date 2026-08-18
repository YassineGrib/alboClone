import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this.prefs);

  final SharedPreferences prefs;
  static const apiKey = 'later.apiBaseUrl';
  static const themeKey = 'later.themeMode';
  static const pendingShareKey = 'later.pendingShare';
  static const languageKey = 'later.app_language';
  static const defaultApi = 'http://127.0.0.1:8080';

  String apiBaseUrl() => prefs.getString(apiKey) ?? defaultApi;

  Future<void> setApiBaseUrl(String value) => prefs.setString(apiKey, value.trim());

  String appLanguage() => prefs.getString(languageKey) ?? 'system';

  Future<void> setAppLanguage(String lang) => prefs.setString(languageKey, lang);

  ThemeMode themeMode() {
    return switch (prefs.getString(themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return prefs.setString(themeKey, value);
  }

  String? pendingShareUrl() => prefs.getString(pendingShareKey);

  Future<void> stashPendingShare(String url) => prefs.setString(pendingShareKey, url);

  Future<void> clearPendingShare() => prefs.remove(pendingShareKey);
}
