# Later — Clipboard Auto-Intake & Emil Kowalski Motion Spec

**Date:** 2026-08-30  
**Slice:** Automatic Clipboard Link Detection & Emil Kowalski Fluid UI Animations  
**Status:** proposed  

---

## 1. Goal

1. **Clipboard Auto-Intake Banner**:
   - Detect URL on device clipboard when the app starts or resumes from background (`AppLifecycleListener` / `WidgetsBindingObserver`).
   - If a valid `http://` or `https://` link is found (and hasn't been dismissed in the current session):
   - Display a floating, springy Toast Banner at the bottom of `SavesScreen` with:
     - Favicon/Site domain badge
     - Truncated URL
     - **"Add Link"** button (adds URL immediately with AI summarization)
     - **"Dismiss"** close button
   - Animate banner entrance with spring slide-up and fade-in, and exit with scale-down.

2. **Emil Kowalski Motion Design & Micro-Interactions**:
   - **Tactile Scale Feedback**: Add interactive `BouncyTap` wrapper for buttons and save cards (scales down to 0.97x on press, springs back to 1.0x).
   - **Staggered Waterfall Entrance**: Add animated entry transitions for Save cards (slide-up + fade-in with staggered index delay).
   - **Pulsing Badges & Glows**: Add smooth pulsing effect on sync indicator badges and floating action buttons.

---

## 2. Architecture & Components

1. **`mobile/lib/ui/core/widgets/bouncy_tap.dart`**:
   - Reusable widget providing tactile scale feedback (`AnimatedScale`, `Curves.easeOutBack`) on tap/press.

2. **`mobile/lib/ui/core/widgets/clipboard_intake_banner.dart`**:
   - Animated floating toast card displaying detected clipboard link with **"Add Link"** and **"Dismiss"** actions.

3. **`mobile/lib/ui/features/saves/saves_screen.dart`**:
   - Add `WidgetsBindingObserver` to check `Clipboard.getData` when app lifecycle reaches `AppLifecycleState.resumed` or `initState`.
   - Embed `ClipboardIntakeBanner` at bottom of `SavesScreen` overlay.

---

## 3. Verification

- Run `flutter analyze` (0 issues).
- Run `flutter test` across all mobile unit & widget tests (44/44 tests passing).
- Manual verification of clipboard detection and spring animations.
