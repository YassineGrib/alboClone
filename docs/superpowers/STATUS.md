# Status

**Stage:** execute (Android share slice)

**Active slice:** Later — Share → Later on Android (`ACTION_SEND` text)

iOS share extension is not in this slice. Rebuild the Android app so the intent filter is installed.

## Run

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8080
```

```bash
cd mobile
flutter run
```

Full restart, not hot reload. Then in Chrome/TikTok/etc: Share → Later.
