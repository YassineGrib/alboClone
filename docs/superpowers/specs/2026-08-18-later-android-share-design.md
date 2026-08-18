# Later — Android share slice

**Date:** 2026-08-18  
**Slice:** receive `ACTION_SEND` text, save a URL  
**Decisions:** `docs/superpowers/decisions/2026-08-18-android-share.md`

## Goal

From Chrome, TikTok, Instagram, or any app: Share → Later. The link lands in the list. Offline still keeps it.

## Out of scope

iOS share extension, images, files, share-to-folder picker, a custom share Activity.

## Behavior

- Intent filter: `SEND` + `text/*`
- Extract first `http`/`https` URL from the payload
- Logged in → `SaveRepository.addUrl`
- Logged out → stash in prefs, drain after login
- No URL → do not create a save
