# Decision: identity, scope cuts, device config

**Date:** 2026-08-18  
**Status:** settled (grill round 3, user accepted recommendations)

Depends on: `2026-08-18-v1-scope.md`, `2026-08-18-stack-and-slice.md`

## Settled

1. **IDs:** client-generated UUID. Same value in Drift and Postgres. `POST /api/saves` accepts the client id.

2. **Collections:** none in slice 1. No `collections` tables, no `collection_id` on saves.

3. **Auth UI:** login only. Seeded dev user. No register screen.

4. **API URL:** in-app debug field so the phone can set the Mac LAN IP without a rebuild. Debug builds allow local HTTP (`Info.plist` ATS exception). HTTPS later.

5. **Name:** **Later**. Bundle / application id `com.bmg.later`.

## Derived (entailed by rounds 1–3, not re-asked)

These are the only consistent reading of the settled rules. Flag them if you disagree.

- **Two statuses, not one.** Content: `pending | ready | failed` (parser, slice 2). Sync: `pending_sync | synced | sync_failed` (offline-first, slice 1). Slice 1 content stays `pending`; the chip the user sees is mostly sync.
- **Conflicts:** last-write-wins. One human, one device first.
- **Delete:** allowed in slice 1. Local tombstone (`deleted_at`) so an offline delete can still reach the server. No silent hard-drop.
- **No note/tags** in slice 1. URL + title (copy of URL) + statuses + timestamps.
- **Token:** `flutter_secure_storage`.
- **Tests:** Pest on Laravel, widget tests on Flutter.
- **Retry:** sync on app foreground + manual retry on `sync_failed`. No fancy backoff engine.
