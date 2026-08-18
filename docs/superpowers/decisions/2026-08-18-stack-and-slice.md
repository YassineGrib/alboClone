# Decision: stack and first slice mechanics

**Date:** 2026-08-18  
**Status:** settled (grill round 2, user accepted recommendations)

Depends on: `2026-08-18-v1-scope.md`

## Settled

1. **Auth:** Laravel Sanctum, email + password. Seed a local user (`you@local.test`) in dev. No social login, no magic links.

2. **Repo:** one repo, `backend/` (Laravel) + `mobile/` (Flutter).

3. **Slice 1 save lifecycle:** client writes locally first as `pending`. Title = the URL. Sync to API still `pending`. `ParseSaveJob` / OG / oEmbed is **slice 2**. Failed parse is also slice 2.

4. **API runtime:** PHP on this Mac. SQLite file at `backend/database/database.sqlite`. No Docker, no Postgres, no Redis. `php artisan serve --host=0.0.0.0 --port=8080`. Phone talks to the Mac's LAN IP. Database queue/Redis wait until the parser slice if we ever need them.

5. **Flutter:** Riverpod. First sideload target is iOS unless you say you only have Android. Same codebase either way.

## Overrides `albo-clone-technical-plan.md`

- "Riverpod (or Bloc)" → **Riverpod**.
- "PostgreSQL (or MySQL)" → **SQLite** for this slice (no Docker).
- Do not add `ParseSaveJob` in the first implementation plan.
- Do not add `receive_sharing_intent` in the first implementation plan.
