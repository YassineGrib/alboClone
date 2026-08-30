# Later — 3-Slide Interactive Onboarding Design Spec

**Date:** 2026-08-30  
**Slice:** Interactive 3-Slide Onboarding Carousel  
**Status:** proposed  

---

## 1. Overview & Goal

Provide a smooth 3-slide onboarding experience showcasing the top features of **Later**:
1. **Share Intake**: Share links directly from TikTok, Instagram, YouTube, and browsers.
2. **AI Enrichment**: Automatic titles, summaries, and smart categorization via Gemini AI.
3. **Save for Later**: Offline-first storage, collections, and map pins.

---

## 2. Onboarding Slide Structure

```
Slide 1: Share From Any App
- Icon: Icons.share_rounded
- Title: "Share From Any App"
- Description: "Save links, videos, recipes, or articles directly from TikTok, Instagram, YouTube, or your browser in one tap."

Slide 2: Smart AI Assistant
- Icon: Icons.auto_awesome_rounded
- Title: "AI Summaries & Tags"
- Description: "Automatic concise titles, AI summaries, and smart categorization so you never lose context."

Slide 3: Save Now, Read Later
- Icon: Icons.bookmark_added_rounded
- Title: "Save Now, Read Calmly"
- Description: "A serene, offline-first home for your saved bookmarks with collections and map view."
```

---

## 3. UI & UX Elements

- **Header Bar**: Top right "Skip" button.
- **PageView Carousel**: Smooth touch swipe between the 3 slides with custom graphics/icons.
- **Page Indicator**: Animated dots/pill indicator showing the current page position (1/3, 2/3, 3/3).
- **Navigation Action**:
  - Slides 1 & 2: "Next" button with arrow icon.
  - Slide 3: "Get Started" button entering the main app.

---

## 4. Testing

- Widget test (`welcome_screen_test.dart`) verifying slide rendering, page navigation via "Next" button, "Skip" action, and completion callback.
