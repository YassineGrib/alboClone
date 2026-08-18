# Decision: Android share sheet

**Date:** 2026-08-18  
**Status:** settled (user: Android ACTION_SEND now; iOS later)

## Settled

1. **Android only.** `ACTION_SEND` + `text/*`. No iOS share extension in this slice.

2. **URLs only.** Pull the first `http(s)` URL out of the shared text. Images, files, and URL-less captions are ignored.

3. **Same save path as paste.** Drift first, then API. Never drop a share because the server is down.

4. **Logged out:** stash the URL, save it after login. Do not require a share UI.

5. **`share_handler`** for the intent. `singleTop` stays. No new Activity.
