# Later — collections slice

**Date:** 2026-08-18  
**Slice:** folders + search + status filters  
**App:** Later (`com.bmg.later`)  
**Decisions:** `docs/superpowers/decisions/2026-08-18-collections.md`

## Goal

Group saves into folders. Find them with a search bar and filters. Offline-first, same as saves.

## Out of scope

Share sheet, map, folder sharing, many-to-many tags, bulk import.

## Data

One nullable `collection_id` on a save. Unfiled = null. Delete folder → unfile, do not delete saves.

Client UUID for folders. Drift schema version 3.

## API

- `GET/POST /api/collections`
- `PATCH/DELETE /api/collections/{id}`
- `PATCH /api/saves/{id}` `{ collection_id }`
- `GET /api/saves?q=&collection_id=&unfiled=1&content_status=`

## App

Search on the list. Folder chips: All / Unfiled / named. Status chips: Any / Ready / Pending / Failed. Folder screen to create, rename, delete. Overflow or long-press to move a save. Adding a URL while a named folder is selected files it there.
