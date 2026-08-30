# Later — Universal Emil Kowalski Motion Spec

**Date:** 2026-08-30  
**Slice:** Universal Emil Kowalski Micro-Interactions & Spring Motion  
**Status:** proposed  

---

## 1. Goal

Expand Emil Kowalski Motion Engineering (`BouncyTap`, spring physics, subtle tactile feedback, staggered card entrances) to **every screen** in the application:
- `WelcomeScreen` (Onboarding Carousel)
- `LoginScreen` (Authentication)
- `SavesScreen` & `SaveDetailScreen` (Link Detail & Actions)
- `CollectionsScreen` & `CollectionDialogs` (Folders & Sharing)
- `SettingsScreen` (Settings Cards & Actions)
- `SaveFilterSheet` (Filters & Sort Options)

---

## 2. Screen-by-Screen Micro-Interactions

1. **`WelcomeScreen`**:
   - Wrap "Skip" button, "Next / Get Started" button, and hero icon badge with `BouncyTap`.
2. **`LoginScreen`**:
   - Wrap "Log in", "Sign in with Google", and "Server" cards with `BouncyTap`.
3. **`CollectionsScreen`**:
   - Wrap folder tiles, "New Folder" FAB, and action tiles with `BouncyTap`.
4. **`SaveDetailScreen`**:
   - Wrap "Open in Browser", "Share Link", "Copy URL", "Move Folder", and priority stars with `BouncyTap`.
5. **`SettingsScreen`**:
   - Wrap "Export Backup", "Restore File", "Test Connection", "Sync Everything Now", "Clear Image Cache", "Log out", and "Delete Account" buttons with `BouncyTap`.

---

## 3. Verification

- Run `flutter analyze` (0 issues).
- Run `flutter test` across all mobile unit & widget tests (45/45 tests passing).
- Manual verification of tactile spring feedback across all screens.
