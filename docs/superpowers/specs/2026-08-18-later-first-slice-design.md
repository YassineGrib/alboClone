# Later — first slice design

**Date:** 2026-08-18  
**Slice:** login + paste-URL list, offline-first, no parser  
**App:** Later (`com.bmg.later`)  
**Decisions:** `docs/superpowers/decisions/`  
**Roadmap only:** `albo-clone-technical-plan.md` (overridden where they disagree)

This spec is the first vertical. It is not the whole Albo clone.

---

## 1. Goal

A person can open Later on an iPhone, log in, paste a URL, and see that save in a list. The row is written to the phone first. If the Mac API is down, the save still exists and the row shows a sync failure they can retry. Nothing is silently dropped.

Success for this slice: that loop works on a sideloaded debug build against Docker on the same LAN.

---

## 2. Out of scope

Share sheet, OG/oEmbed parser, collections, map, collaborators, register, TikTok/Instagram import, push, IAP, stores, HTTPS, VPS.

`ParseSaveJob` is slice 2. Content status stays `pending`. Title equals the URL.

---

## 3. Who

One human (the developer), maybe later a second. Sideload only. Seeded account in development:

- email: `you@local.test`
- password: `password`

---

## 4. Architecture

Monorepo:

```
backend/     Laravel, Sanctum, SQLite (file)
mobile/       Flutter, Riverpod, Drift, Dio
```

Flutter layers (Riverpod, not Bloc, not ChangeNotifier ViewModels):

```
mobile/lib/
  data/          # Dio API, Drift, secure storage — no widgets
  domain/        # Save, User, enums — immutable
  ui/
    core/        # theme, widgets (status chip, empty state)
    features/
      auth/
      saves/
      settings/
```

- **Services** talk to HTTP, SQLite, Keychain.
- **Repositories** are the source of truth. They write Drift first, then attempt the API.
- **Notifiers** (Riverpod) hold screen state. Widgets do not call Dio.

Laravel is a JSON API only. No Blade UI.

---

## 5. Data

### 5.1 Postgres `saves`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | Client-generated. Server must not mint a different id. |
| user_id | uuid FK | |
| url | text | Required, max 2048 chars |
| title | text | Slice 1: copy of url |
| content_status | enum | `pending` \| `ready` \| `failed`. Slice 1 always `pending` |
| deleted_at | timestamptz null | Tombstone. Null = alive |
| created_at | timestamptz | Client may send; server stores |
| updated_at | timestamptz | Last-write-wins |

No `collection_id`, notes, tags, lat/lng, or `raw_metadata` in this slice.

### 5.2 Postgres `users`

Standard Laravel users. Sanctum tokens. No extra profile fields.

### 5.3 Drift `saves`

Same columns plus:

| Column | Type | Notes |
|---|---|---|
| sync_status | text | `pending_sync` \| `synced` \| `sync_failed` |
| sync_error | text null | Last error, shown on the chip / retry |

Local insert happens before any HTTP call. `id` is a UUID v4 generated on the device.

### 5.4 Two statuses

They are not one field.

- **content_status** = parsing (slice 2). Slice 1: always `pending`.
- **sync_status** = whether the server has this row. This is what the list chip shows in slice 1.

---

## 6. API

Base: `http://<lan-ip>:8080/api`  
Auth: `Authorization: Bearer <token>` except login.

| Method | Path | Behavior |
|---|---|---|
| POST | `/api/login` | `{ email, password }` → `{ token, user: { id, email } }`. 422 on bad credentials. |
| POST | `/api/logout` | Invalidate current token. 204. |
| GET | `/api/saves` | Alive saves for the user, newest first. Query `updated_since` (ISO-8601) optional for pull. |
| POST | `/api/saves` | `{ id, url, title, created_at }`. Idempotent on `id`. If the uuid exists for this user, return the existing row (200). If it exists for another user, 409. Validate url. Set `content_status=pending`. |
| DELETE | `/api/saves/{id}` | Set `deleted_at` now. 204. Repeat DELETE is 204. 404 if never existed. |

No register. No PATCH in this slice (nothing editable except delete).

List endpoint never returns tombstones. After a delete has synced, the client removes the local row.

---

## 7. Client flows

### 7.1 First launch

Settings defaults: theme = System, API URL = `http://127.0.0.1:8080` (simulator) — the human replaces this with the Mac LAN IP on a real device.

Login screen: email, password, Log in. On success, store token in `flutter_secure_storage`, go to the list.

### 7.2 Save

1. User pastes a URL into the field on the list screen and submits.
2. Validate: non-empty, must parse as `http` or `https`. Show a one-line error under the field if not. Do not create a row.
3. Generate UUID. Insert Drift row: `title = url`, `content_status = pending`, `sync_status = pending_sync`.
4. List updates immediately.
5. POST `/api/saves`. On 200: `synced`. On network/4xx/5xx: `sync_failed` + message. Row stays.

### 7.3 Sync

Triggers: app returns to foreground; user pulls to refresh; user taps Retry on a `sync_failed` row.

Order: push local `pending_sync` / `sync_failed` creates and deletes, then GET `/api/saves`. Last-write-wins: server `updated_at` wins on pull if the local row is already `synced`. Local `pending_sync` is never overwritten by pull.

### 7.4 Delete

Swipe or overflow → Delete. Set local `deleted_at` and hide from the list immediately. If the row was never synced, just delete the Drift row. If it was synced or `pending_sync`, keep a tombstone until DELETE `/api/saves/{id}` succeeds, then purge local.

### 7.5 Logout

Clear token, clear in-memory session, go to login. Keep local Drift data (sideload, one user). Next login as the seeded user reuses the same rows.

---

## 8. UI

Skills when implementing screens: `minimalist-ui`, `impeccable` (dual-mode, no slop).

### 8.1 Screens (three)

1. **Login** — wordmark “Later”, two fields, one primary button. Link-style control: “Server” opens settings (API URL + appearance) so a device can be pointed at the Mac before the first login.
2. **List** — top: paste field + Add. Body: one row per save (title = URL, one status chip). Empty: “Paste a link you want back later.” No cards-in-cards, no illustrations.
3. **Settings** — API URL text field, appearance segmented control (System / Light / Dark), Log out. Reached from a gear on the list app bar.

### 8.2 Theme

| Token | Light | Dark |
|---|---|---|
| Canvas | `#F7F6F3` | `#1C1C1A` |
| Surface | `#FFFEFC` | `#2A2A27` |
| Ink | `#2F3437` | `#EDEDEC` |
| Muted | `#787774` | `#9B9A97` |
| Line | `#EAEAEA` | `#3A3A36` |
| Primary button | ink on canvas inverted: `#2F3437` bg, `#FFFEFC` text | `#EDEDEC` bg, `#1C1C1A` text |
| Chip pending_sync | pale yellow `#FBF3DB` / `#956400` | same hues, darkened canvas |
| Chip synced | pale green `#EDF3EC` / `#346538` | same |
| Chip sync_failed | pale red `#FDEBEC` / `#9F2F2D` | same |

Never `#000000` or `#FFFFFF` as the page background. Contrast must pass WCAG AA for body text and the primary button in both modes. Hierarchy is the same in light and dark: no extra shadows or neon to “make dark mode interesting.”

Radius: 8px on fields and the Add / Log in buttons. Chips may be fully rounded. No drop shadows. No gradients.

Type: platform fonts, body 16–17, URL lines can wrap twice then ellipsis. Status chip: 11px, uppercase, wide tracking.

### 8.3 Copy

Plain. Banned: Elevate, Seamless, Unleash, Next-Gen, “your content hub.” Errors name the failure: “Couldn’t reach the server.” “That isn’t a URL.”

---

## 9. Errors and edge cases

- **Offline create:** local row + `sync_failed` (or stay `pending_sync` until the first attempt fails). Chip + Retry.
- **Duplicate POST:** same uuid, same user → 200 existing row. Client treats as `synced`.
- **Invalid URL:** no local row.
- **401:** send to login. Keep Drift.
- **Wrong API URL:** login fails with “Couldn’t reach the server.” Settings stay reachable from the login screen.
- **iOS cleartext:** debug `Info.plist` allows local HTTP. Release ATS stays default (out of this slice to ship HTTPS).
- **Empty list after delete-all:** empty state, not a blank scaffold.
- **Very long URL:** stored in full, displayed with ellipsis after two lines.

---

## 10. Testing

Laravel (Pest):

- login 200 and 422
- unauthenticated GET `/api/saves` → 401
- POST save with client uuid persists that uuid
- POST same uuid again → 200, one row
- DELETE then GET omits the row; second DELETE → 204

Flutter:

- repository: inserting a save writes Drift before Dio is called (mock Dio down → row still there, `sync_failed`)
- widget: list shows a pasted URL without waiting on HTTP
- widget: theme System / Light / Dark rebuilds with the tokens above

Do not claim done without running these.

---

## 11. Runtime

No Docker. Laravel runs on the host:

```bash
cd backend
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8080
```

Database: SQLite at `backend/database/database.sqlite`. Sessions, cache, and queue use `file` / `sync`. Redis is not installed.

Flutter debug: API URL is the settings field (simulator default `http://127.0.0.1:8080`).

iOS first. Android must still compile (same project).

---

## 12. File map (create in implementation, not now)

```
backend/   # laravel new
  database/database.sqlite
  database/migrations/xxxx_create_saves_table.php
  app/Http/Controllers/Api/AuthController.php
  app/Http/Controllers/Api/SaveController.php
  database/seeders/DevUserSeeder.php
mobile/    # flutter create --org com.bmg --project-name later
  lib/data/services/api_client.dart
  lib/data/services/local_db.dart
  lib/data/repositories/save_repository.dart
  lib/data/repositories/auth_repository.dart
  lib/domain/models/save.dart
  lib/ui/core/theme/later_theme.dart
  lib/ui/features/auth/login_screen.dart
  lib/ui/features/saves/saves_screen.dart
  lib/ui/features/settings/settings_screen.dart
```

---

## 13. Global constraints

- Never drop a local save because HTTP failed.
- Never mint a server-side id for a save.
- Never parse OG tags in this slice.
- Never add collections, notes, or a register screen.
- Dual theme from the first pixel of UI. No light-only placeholder.
