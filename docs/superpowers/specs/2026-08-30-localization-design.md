# Later — Full App Localization Spec (English, Arabic RTL, French)

**Date:** 2026-08-30  
**Slice:** Multi-Language Support & Full Arabic RTL  
**Status:** proposed  

---

## 1. Goal & Architecture

Provide complete, high-quality localization across **English (`en`)**, **Arabic (`ar`) with full RTL directionality**, and **French (`fr`)** for all user-facing strings in the app:
- Onboarding Carousel (`WelcomeScreen`)
- Authentication (`LoginScreen`)
- Saves & Link Intake (`SavesScreen`, `AddSaveSheet`, `SaveCard`)
- Collections & Sharing (`CollectionsScreen`, `CollectionDialogs`)
- Settings & Backup/Restore (`SettingsScreen`)

---

## 2. Localization Provider & Delegate

Create `mobile/lib/l10n/app_localizations.dart`:
- Implements `LocalizationsDelegate<AppLocalizations>` registered in `MaterialApp`.
- Provides static helper `AppLocalizations.of(context)` and convenient Extension `context.l10n` for easy access in UI widgets.
- Contains complete translations maps for `en`, `ar`, and `fr`.

---

## 3. UI Integration Strategy

1. **`app.dart`**: Register `AppLocalizations.delegate` in `localizationsDelegates`.
2. **`WelcomeScreen`**: Localize slide titles, descriptions, feature tags, "Skip", "Next", and "Get Started".
3. **`LoginScreen`**: Localize form titles, toggle segments ("Log in" / "Create account"), input labels, hints, submit buttons, Google Sign-In, error notes, and Server card.
4. **`SettingsScreen`**: Localize section headers ("Backup & Restore", "Server Connection", "Sync Status", "Appearance", "Language", "Cache & Storage", "Legal & Privacy", "Session & Account") and action buttons.
5. **RTL Directionality**: Arabic (`ar`) automatically flips layout directionality (Right-to-Left) via Flutter's built-in `Directionality` & `GlobalWidgetsLocalizations.delegate`.

---

## 4. Verification

- Run `flutter analyze` (0 issues).
- Run `flutter test` across unit & widget test suite (44/44 tests passing).
- Verify language switching between Auto / EN / AR / FR in Settings.
