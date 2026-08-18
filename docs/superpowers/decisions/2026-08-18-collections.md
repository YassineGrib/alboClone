# Decision: collections as folders

**Date:** 2026-08-18  
**Status:** settled (user asked for folders + search/filters; skipped share sheet)

## Settled

1. **A save lives in one folder, or none.**  
   `collection_id` is nullable. Unfiled is `null`. Not many-to-many tags.

2. **Deleting a folder unfiles saves.**  
   It does not delete saves.

3. **No sharing this slice.**  
   Folders are personal. Collaborators stay later.

4. **Search and filters are local-first.**  
   Title + URL search. Folder chips: All / Unfiled / named. Status chips: Any / Ready / Pending / Failed. The API also accepts `q`, `collection_id`, `unfiled`, `content_status` for later sync use.

5. **Client UUIDs** for collections, same as saves. Server does not mint folder ids.

6. **Client IDs stay the source of truth offline.**  
   Create the folder in Drift, then POST. Never drop a folder because the API is down.
