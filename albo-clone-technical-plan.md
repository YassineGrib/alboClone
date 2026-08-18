# Save-for-Later App — Technical Plan
### Clone reference: Albo (formerly Sortd) — `com.thesortdapp.sortd`
### Stack: Flutter (mobile) + Laravel (backend)

---

## 1. Product Overview

A universal "save for later" app. Users save links, videos, recipes, workouts, and places from anywhere (mostly via the OS share sheet from TikTok, Instagram, browsers, etc.). The app auto-detects the content type, extracts metadata, and organizes saves into collections — with map view, search, and collaborative sharing.

**Core value proposition:** turn "I'll check this later" into "done."

### Reference app features (Google Play listing)
- Save links, videos, books, recipes, workouts, tools, places
- Map view — saves with a location get pinned
- Smart collections for organizing
- Share collections with friends, plan together
- Fast, simple save flow
- Bulk import (e.g. TikTok liked videos, capped at ~40/day per user reviews)

### Known pain points from real user reviews (design around these)
- **Sync reliability** — saves silently disappearing or not persisting is the #1 complaint. Solve with offline-first local cache + explicit sync status shown to the user.
- **Import breakage** — TikTok/Instagram video imports stop working after a few days; likely due to unofficial API/scraper fragility and rate limits. Treat platform importers as a high-maintenance component, not a "build once" feature.
- **Daily import caps** cause confusion when users hit them without warning — show remaining quota clearly in the UI.

---

## 2. Core Feature Set (MVP)

1. **Save via Share Extension** — intercept shares from other apps (iOS Share Extension / Android `ACTION_SEND` intent)
2. **Auto-parsing** — detect type (recipe / video / place / article / product) and extract title, thumbnail, description, location
3. **Collections** — user-created folders/tags to organize saves
4. **Map view** — pin location-based saves (restaurants, places) on a map
5. **Search & filter** — across all saves, by type/collection
6. **Sharing & collaboration** — share a collection via link, collaborative lists
7. **Bulk import** — import liked/saved content from TikTok etc., with a daily cap

---

## 3. Architecture

### Backend — Laravel
| Concern | Choice |
|---|---|
| Auth | Laravel Sanctum (mobile token auth) |
| Queues | Laravel Queue, Redis driver — for async link parsing, scraping, imports |
| Database | PostgreSQL (or MySQL) via Eloquent |
| File storage | S3-compatible bucket (or local disk for dev) for cached thumbnails |
| Scheduler | Laravel Task Scheduling — retry failed parses, clean up stale import jobs |
| Push notifications | Laravel Notifications + FCM channel |
| Real-time (optional, phase 2) | Laravel Reverb (self-hosted WebSockets) or Pusher |

### Mobile — Flutter
| Concern | Choice |
|---|---|
| State management | Riverpod (or Bloc) |
| Local DB / offline cache | Drift (SQLite) |
| HTTP client | Dio, with interceptors for auth token refresh |
| Share intercept | `receive_sharing_intent` package (handles iOS Share Extension + Android intents) |
| Maps | `google_maps_flutter` or `flutter_map` (Mapbox) + clustering plugin |
| Push | `firebase_messaging` |

---

## 4. Data Model

```
users
  id, email, password, plan, created_at, updated_at

saves
  id, user_id (FK), url, type (enum: link/video/recipe/place/article/product),
  status (enum: pending/ready/failed), title, image_url, description,
  lat, lng, raw_metadata (json), collection_id (FK, nullable),
  created_at, updated_at

collections
  id, user_id (FK), name, icon, is_shared (bool), share_token,
  created_at, updated_at

collection_members
  id, collection_id (FK), user_id (FK), role (enum: owner/editor/viewer),
  created_at

import_jobs
  id, user_id (FK), source (enum: tiktok/instagram/...), status,
  items_total, items_done, started_at, finished_at, error_log
```

---

## 5. API Design (Laravel routes)

```
Auth
POST   /api/register
POST   /api/login
POST   /api/logout

Saves
POST   /api/saves                    -> create (URL + optional note), returns immediately with status=pending
GET    /api/saves                    -> paginated list, filter by collection/type/status
GET    /api/saves/{id}
PATCH  /api/saves/{id}                -> move to collection, edit note/tags
DELETE /api/saves/{id}

Collections
POST   /api/collections
GET    /api/collections
GET    /api/collections/{id}
PATCH  /api/collections/{id}
DELETE /api/collections/{id}
POST   /api/collections/{id}/share    -> generate/return share token & public link
POST   /api/collections/{id}/members  -> invite a collaborator

Import
POST   /api/import/tiktok             -> kicks off ImportJob, returns job id
GET    /api/import/{jobId}            -> poll status (items_done / items_total)
```

### Save creation flow
1. Client `POST /api/saves` with the raw URL
2. Laravel inserts row with `status: pending`, returns it immediately (optimistic UI on client)
3. `ParseSaveJob` dispatched to queue
4. Job fetches OG tags / oEmbed / schema.org JSON-LD, updates row to `status: ready`
5. Client picks up the update via polling (`GET /api/saves?status=pending`) or a push/broadcast event in later phases

---

## 6. Link Parsing Pipeline

- **Generic sites**: Open Graph tags (`spatie/laravel-og` or a DOM crawler like `symfony/dom-crawler`) for title/image/description
- **Recipes**: parse `<script type="application/ld+json">` for schema.org `Recipe` structured data — widely supported by recipe sites
- **Places**: Google Places API / Apple Maps lookup for lat/lng + place details
- **TikTok**: use TikTok's official oEmbed endpoint for public videos first (no auth required) before considering scraping
- **Instagram/other platforms**: oEmbed where available; bulk "import your likes" requires OAuth login to that platform — treat as a later phase, not MVP
- Apply job-level rate limiting (Laravel's `RateLimited` middleware) to avoid hammering external APIs and to self-impose safe daily caps
- Design for partial failure: if parsing fails, mark `status: failed` with a reason, allow manual retry — never leave a save silently stuck

---

## 7. Build Phases

1. **Share Extension + basic save flow** — native share-sheet intercept (iOS Share Extension, Android Intent Filter) posts a URL to the backend; minimal app that lists raw saves, no parsing yet
2. **Link parsing pipeline** — async worker fetches OG tags, oEmbed data, schema.org JSON-LD to auto-fill title/image/type; queue-based so saving feels instant
3. **Collections and organization** — create collections, tag/move saves, auto-suggest a collection based on detected type
4. **Map view** — geocode and pin location-based saves; use a maps SDK with clustering for dense areas
5. **Sharing and collaboration** — shareable collection links, collaborative lists where multiple users can add to the same collection
6. **Platform-specific importers** — bulk import from TikTok/Instagram, respecting rate limits; most fragile part, plan for breakage and daily caps
7. **Polish, offline support, monetization** — offline-first sync, push notification reminders, subscription tier for higher import limits or AI features

### Suggested day-to-day build order
1. Laravel: Sanctum auth + `saves`/`collections` CRUD, no parsing yet
2. Flutter: login screen, save list screen, manual "paste a URL to save" input (skip share extension at first — validate the core loop with an in-app text field)
3. Add `ParseSaveJob` + OG/schema.org parsing, wire up pending → ready state in Flutter
4. Add `receive_sharing_intent` for real share-sheet saving
5. Collections + tagging UI
6. Map view for location-type saves
7. Collection sharing (shareable token, public read-only view)
8. TikTok/Instagram importers last

---

## 8. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Saves not syncing / disappearing (top complaint in reviews) | Offline-first local DB (Drift) + explicit sync status UI; never silently drop a save |
| Platform scrapers breaking (TikTok/Instagram) | Prefer official oEmbed APIs; isolate importer logic so breakage doesn't affect core save flow; alert users clearly when an import fails |
| Slow/blocking saves | Always async — return `pending` immediately, parse in background |
| Users confused by daily import caps | Surface remaining quota in UI before they hit the limit |
| Scaling image/thumbnail storage | Use S3-compatible storage with a CDN in front from day one |

---


## 9. Package Reference (Flutter)

```
receive_sharing_intent   # share-sheet intercept
drift                    # local SQLite offline cache
riverpod                 # state management
dio                      # HTTP client
google_maps_flutter      # or flutter_map (Mapbox)
firebase_messaging       # push notifications
```

## 9.1 Package Reference (Laravel)

```
laravel/sanctum          # mobile token auth
spatie/laravel-og        # Open Graph parsing (or symfony/dom-crawler)
laravel/reverb            # optional, phase 2 real-time updates
predis/predis or phpredis # Redis driver for queues
```
