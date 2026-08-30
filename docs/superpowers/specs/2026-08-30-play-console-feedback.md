# Later — Play Console Closed Testing Feedback Fixes Spec

**Date:** 2026-08-30  
**Slice:** Play Console Closed Testing Feedback Remediation  
**Status:** proposed  

---

## 1. Issue 1: Large Font Accessibility & Screen Responsiveness

### Problem
Testers with large font sizes enabled on Android couldn't scroll down to tap action buttons (e.g. "Get Started" on Onboarding, "Log in" on Auth screen).

### Solution
1. **Text Scaler Clamping**: Apply `MediaQuery.override(child: ..., textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.8, maxScaleFactor: 1.35))` on app level in `LaterApp` so text remains readable without exploding container dimensions beyond screen bounds.
2. **Onboarding Responsiveness (`WelcomeScreen`)**:
   - Wrap `WelcomeScreen` body inside `LayoutBuilder` & `SingleChildScrollView` with `ConstrainedBox`.
   - Ensure bottom button ("Next" / "Get Started") and skip button are always scrollable and reachable regardless of screen height or font scale.
3. **Auth Responsiveness (`LoginScreen`)**:
   - Ensure all input fields and action buttons scroll gracefully on small screens or large font scales.

---

## 2. Issue 2: Settings Visual Hierarchy & Section Grouping

### Problem
Testers reported: *"Sections in settings could be better highlighted. Hard to read where one section of the settings begins and where ends at first glance."*

### Solution
1. **Card Section Containers**: Group each settings topic (Backup & Restore, Server Connection, Appearance, Language, Image Cache, Gemini AI, Legal & Privacy, Account) inside a distinct `Card` container with rounded borders (`BorderRadius.circular(16)`), subtle elevation/background, and clear padding.
2. **Colored Icon Header Badges**: Add distinct colored icon badges for each section header (e.g. Blue for Backup, Amber for Gemini AI, Purple for Storage, Teal for Appearance) so sections are visually obvious at first glance.
3. **Spacing & Dividers**: Increase separation between setting cards to 16dp to create clean, readable visual boundaries.

---

## 3. Verification Plan

- Run `flutter analyze` to ensure zero lints/warnings.
- Run `flutter test` across all 44 widget and unit tests to ensure all tests pass.
- Test `WelcomeScreen` and `SettingsScreen` with large font scale (e.g. textScaler 1.5x) to verify responsiveness and scrolling.
