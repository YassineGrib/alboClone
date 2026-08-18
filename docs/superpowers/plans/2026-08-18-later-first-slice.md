# Later First Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Later so a sideloaded iPhone can log in, paste a URL, see it in a list written to Drift first, and retry if the Docker API is down.

**Architecture:** Monorepo. Laravel JSON API in `backend/` (Sanctum, UUID saves, tombstones). Flutter in `mobile/` (Riverpod, Drift, Dio). Repositories write locally before HTTP. Dual-theme minimalist UI.

**Tech Stack:** Laravel, Sanctum, SQLite, Flutter, Riverpod, Drift, Dio, flutter_secure_storage. No Docker.

**Spec:** `docs/superpowers/specs/2026-08-18-later-first-slice-design.md`

## Global Constraints

- Never drop a local save because HTTP failed.
- Never mint a server-side id for a save. Client UUID only.
- Never parse OG tags in this slice. `content_status` is always `pending`. Title = URL.
- Never add collections, notes, or a register screen.
- Dual theme from the first pixel of UI. No light-only placeholder.
- Seeded user: `you@local.test` / `password`.
- App id: `com.bmg.later`. Display name: Later.
- API: `http://<lan-ip>:8080/api`. Debug HTTP allowed on iOS.
- Copy: “Couldn’t reach the server.” “That isn’t a URL.” Empty: “Paste a link you want back later.”
- Users table uses UUID primary keys (spec `user_id` uuid FK).
- Commits only if the human asked. Prefer working tree over empty commit noise.

## File map

```
compose.yaml
backend/                          # laravel/laravel
  app/Models/User.php               # HasUuids
  app/Models/Save.php
  app/Http/Controllers/Api/AuthController.php
  app/Http/Controllers/Api/SaveController.php
  app/Http/Requests/LoginRequest.php
  app/Http/Requests/StoreSaveRequest.php
  database/migrations/*_create_users_table.php
  database/migrations/*_create_saves_table.php
  database/seeders/DevUserSeeder.php
  routes/api.php
  tests/Feature/AuthApiTest.php
  tests/Feature/SaveApiTest.php
mobile/                             # flutter create
  lib/domain/models/save.dart
  lib/domain/models/user.dart
  lib/data/services/api_client.dart
  lib/data/services/local_database.dart
  lib/data/repositories/auth_repository.dart
  lib/data/repositories/save_repository.dart
  lib/data/repositories/settings_repository.dart
  lib/ui/core/theme/later_theme.dart
  lib/ui/core/widgets/sync_chip.dart
  lib/ui/features/auth/login_screen.dart
  lib/ui/features/saves/saves_screen.dart
  lib/ui/features/settings/settings_screen.dart
  lib/app.dart
  lib/main.dart
  test/save_repository_test.dart
  test/saves_screen_test.dart
  test/later_theme_test.dart
  ios/Runner/Info.plist             # NSAppTransportSecurity for debug
```

---

### Task 1: Scaffold monorepo

**Files:**
- Create: `compose.yaml`, `backend/` (generated), `mobile/` (generated), `.gitignore`
- Modify: `backend/.env`, `backend/.env.example`, Laravel user migration to UUID

**Interfaces:**
- Consumes: nothing
- Produces: Laravel app at `backend/` serving later via compose on port 8080; Flutter app `com.bmg.later`; Postgres db `later`

This task is generated project + config. TDD starts at Task 2.

- [ ] **Step 1: Git init and ignore**

```gitignore
.DS_Store
.claude/
.cursor/
backend/vendor/
backend/node_modules/
backend/.env
backend/storage/logs/*.log
backend/storage/framework/cache/*
backend/storage/framework/sessions/*
backend/storage/framework/views/*
backend/bootstrap/cache/*.php
mobile/.dart_tool/
mobile/build/
mobile/.idea/
mobile/*.iml
```

Keep `docs/`, `AGENTS.md`, specs, and plans tracked.

- [ ] **Step 2: Create Laravel app**

Run from repo root:

```bash
composer create-project laravel/laravel backend --no-interaction
cd backend && composer require laravel/sanctum --no-interaction && php artisan pest:install --no-interaction
```

If `pest:install` is missing: `composer require pestphp/pest --dev --with-all-dependencies` then `vendor/bin/pest --init`.

- [ ] **Step 3: UUID users**

Replace the default users `id` bigIncrements with `$table->uuid('id')->primary();`. On `app/Models/User.php` add `use Illuminate\Database\Eloquent\Concerns\HasUuids;` and `HasUuids` on the class.

- [ ] **Step 4: Create Flutter app**

```bash
flutter create --org com.bmg --project-name later --platforms=ios,android mobile
```

Open `mobile/pubspec.yaml` and set `name: later`. Display name Later in iOS `CFBundleDisplayName` and Android `android:label`.

- [ ] **Step 5: Docker Compose**

Create `compose.yaml`:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: later
      POSTGRES_USER: later
      POSTGRES_PASSWORD: later
    ports:
      - "5432:5432"
    volumes:
      - later_pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U later"]
      interval: 5s
      timeout: 5s
      retries: 10
  redis:
    image: redis:7
    ports:
      - "6379:6379"
  backend:
    image: php:8.4-cli
    working_dir: /app
    volumes:
      - ./backend:/app
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    command: php artisan serve --host=0.0.0.0 --port=8080
    environment:
      APP_ENV: local
      DB_CONNECTION: pgsql
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: later
      DB_USERNAME: later
      DB_PASSWORD: later
      REDIS_HOST: redis

volumes:
  later_pg:
```

For local tests (Pest on the Mac, not in the PHP container), also set `backend/.env` `DB_*` to the same Postgres on `127.0.0.1`. Prefer running Pest against Docker Postgres: `docker compose up -d postgres redis` then `php artisan serve` on the host at 8080 if the PHP image lacks extensions. If the `php:8.4-cli` image cannot talk pgsql, **do not fight it**: run Postgres+Redis in Docker and run Laravel on the host:

```yaml
# If host PHP has pdo_pgsql (check: php -m | grep pgsql)
# compose only postgres+redis; Laravel: php artisan serve --host=0.0.0.0 --port=8080
```

Ruling if pdo_pgsql missing on host: install via `pecl`/`brew` or use a `backend/Dockerfile` FROM `php:8.4-cli` with `docker-php-ext-install pdo_pgsql pcntl`. Prefer a small `backend/Dockerfile` so compose `backend` works.

- [ ] **Step 6: Verify scaffold**

```bash
php -m | grep pgsql
docker compose up -d postgres redis
cd backend && php artisan --version
cd ../mobile && flutter pub get && flutter analyze
```

Expected: Laravel version prints; Flutter analyze has no errors in the blank app (or only info).

---

### Task 2: Auth API (TDD)

**Files:**
- Create: `backend/tests/Feature/AuthApiTest.php`, `backend/app/Http/Controllers/Api/AuthController.php`, `backend/app/Http/Requests/LoginRequest.php`, `backend/database/seeders/DevUserSeeder.php`
- Modify: `backend/routes/api.php`, `backend/bootstrap/app.php` (Sanctum API), `backend/database/seeders/DatabaseSeeder.php`

**Interfaces:**
- Consumes: User model with HasUuids
- Produces: `POST /api/login` → `{ token, user: { id, email } }`; `POST /api/logout` Bearer, 204

- [ ] **Step 1: Write the failing test**

Create `backend/tests/Feature/AuthApiTest.php`:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

it('logs in with email and password and returns a token', function () {
    $user = User::factory()->create([
        'email' => 'you@local.test',
        'password' => 'password',
    ]);

    $response = $this->postJson('/api/login', [
        'email' => 'you@local.test',
        'password' => 'password',
    ]);

    $response->assertOk()
        ->assertJsonPath('user.email', 'you@local.test')
        ->assertJsonStructure(['token', 'user' => ['id', 'email']]);

    expect($response->json('user.id'))->toBe($user->id);
});

it('rejects bad credentials with 422', function () {
    User::factory()->create([
        'email' => 'you@local.test',
        'password' => 'password',
    ]);

    $this->postJson('/api/login', [
        'email' => 'you@local.test',
        'password' => 'nope',
    ])->assertUnprocessable();
});

it('logs out the current token', function () {
    $user = User::factory()->create();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/logout')
        ->assertNoContent();
});
```

User factory must hash passwords with `'password' => 'password'` meaning bcrypt via factory definition `Hash::make` or `'password' => bcrypt('password')`. Default Laravel factory already hashes `password`. Pass `'password' => 'password'` only if the factory hashes it; otherwise use `Hash::make('password')` in the test create array (Laravel hashes if you set the attribute through Eloquent mutator). Prefer:

```php
'password' => 'password',
```

and keep `User::$hidden` + hashed cast `'password' => 'hashed'`.

- [ ] **Step 2: Run test to verify it fails**

```bash
cd backend && php artisan test --filter=AuthApiTest
```

Expected: FAIL (route not defined or 404).

- [ ] **Step 3: Minimal implementation**

`routes/api.php`:

```php
<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);
```

`AuthController`:

```php
public function login(LoginRequest $request)
{
    $user = User::where('email', $request->email)->first();
    if (! $user || ! Hash::check($request->password, $user->password)) {
        throw ValidationException::withMessages([
            'email' => ['Couldn’t reach the account with those credentials.'],
        ]);
    }
    // Spec error for bad login is 422. Keep message generic, not "couldn't reach server".
    $token = $user->createToken('mobile')->plainTextToken;
    return response()->json([
        'token' => $token,
        'user' => ['id' => $user->id, 'email' => $user->email],
    ]);
}

public function logout(Request $request)
{
    $request->user()->currentAccessToken()->delete();
    return response()->noContent();
}
```

LoginRequest: `email` required|email, `password` required|string.

DevUserSeeder:

```php
User::query()->firstOrCreate(
    ['email' => 'you@local.test'],
    ['name' => 'You', 'password' => 'password'],
);
```

Call it from DatabaseSeeder.

Ensure `bootstrap/app.php` has `api` prefix and Sanctum. Publish sanctum if needed: `php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"`.

User factory: uuid ids work with HasUuids automatically.

- [ ] **Step 4: Run tests**

```bash
cd backend && php artisan test --filter=AuthApiTest
```

Expected: PASS.

---

### Task 3: Saves API (TDD)

**Files:**
- Create: `backend/app/Models/Save.php`, `backend/database/migrations/xxxx_create_saves_table.php`, `backend/app/Http/Controllers/Api/SaveController.php`, `backend/app/Http/Requests/StoreSaveRequest.php`, `backend/tests/Feature/SaveApiTest.php`
- Modify: `backend/routes/api.php`

**Interfaces:**
- Consumes: Sanctum user
- Produces: `Save` model `{ id: uuid, user_id, url, title, content_status, deleted_at, created_at, updated_at }`; routes GET/POST/DELETE `/api/saves`

- [ ] **Step 1: Write the failing test**

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;

uses(RefreshDatabase::class);

function authUser(): User {
    $user = User::factory()->create();
    test()->actingAs($user, 'sanctum');
    return $user;
}

it('rejects unauthenticated listing', function () {
    $this->getJson('/api/saves')->assertUnauthorized();
});

it('stores a save with the client uuid', function () {
    authUser();
    $id = (string) Str::uuid();

    $this->postJson('/api/saves', [
        'id' => $id,
        'url' => 'https://example.com/x',
        'title' => 'https://example.com/x',
    ])->assertOk()
        ->assertJsonPath('id', $id)
        ->assertJsonPath('content_status', 'pending');

    $this->assertDatabaseHas('saves', ['id' => $id, 'url' => 'https://example.com/x']);
});

it('is idempotent for the same uuid and user', function () {
    authUser();
    $id = (string) Str::uuid();
    $payload = ['id' => $id, 'url' => 'https://example.com/x', 'title' => 'https://example.com/x'];

    $this->postJson('/api/saves', $payload)->assertOk();
    $this->postJson('/api/saves', $payload)->assertOk();

    expect(\App\Models\Save::query()->count())->toBe(1);
});

it('returns 409 when uuid belongs to another user', function () {
    $id = (string) Str::uuid();
    $owner = User::factory()->create();
    \App\Models\Save::query()->create([
        'id' => $id,
        'user_id' => $owner->id,
        'url' => 'https://example.com/x',
        'title' => 'https://example.com/x',
        'content_status' => 'pending',
    ]);

    authUser();
    $this->postJson('/api/saves', [
        'id' => $id,
        'url' => 'https://example.com/y',
        'title' => 'https://example.com/y',
    ])->assertStatus(409);
});

it('lists alive saves newest first and omits tombstones', function () {
    $user = authUser();
    $old = \App\Models\Save::query()->create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'url' => 'https://example.com/old',
        'title' => 'https://example.com/old',
        'content_status' => 'pending',
        'created_at' => now()->subDay(),
    ]);
    $new = \App\Models\Save::query()->create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'url' => 'https://example.com/new',
        'title' => 'https://example.com/new',
        'content_status' => 'pending',
    ]);
    \App\Models\Save::query()->create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'url' => 'https://example.com/gone',
        'title' => 'https://example.com/gone',
        'content_status' => 'pending',
        'deleted_at' => now(),
    ]);

    $ids = $this->getJson('/api/saves')->assertOk()->json();
    expect(collect($ids)->pluck('id')->all())->toBe([$new->id, $old->id]);
});

it('tombstones on delete and second delete is 204', function () {
    $user = authUser();
    $id = (string) Str::uuid();
    \App\Models\Save::query()->create([
        'id' => $id,
        'user_id' => $user->id,
        'url' => 'https://example.com/x',
        'title' => 'https://example.com/x',
        'content_status' => 'pending',
    ]);

    $this->deleteJson("/api/saves/{$id}")->assertNoContent();
    $this->deleteJson("/api/saves/{$id}")->assertNoContent();
    $this->getJson('/api/saves')->assertOk()->assertExactJson([]);
});

it('returns 404 when deleting an id that never existed', function () {
    authUser();
    $this->deleteJson('/api/saves/'.Str::uuid())->assertNotFound();
});
```

- [ ] **Step 2: Run to verify fail**

```bash
cd backend && php artisan test --filter=SaveApiTest
```

Expected: FAIL (missing model/route).

- [ ] **Step 3: Migration and model**

```php
Schema::create('saves', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
    $table->text('url');
    $table->text('title');
    $table->string('content_status')->default('pending');
    $table->timestamp('deleted_at')->nullable();
    $table->timestamps();
});
```

Save model: `$incrementing = false; $keyType = 'string';` fillable the columns. Do not use SoftDeletes trait if it would hide rows from the 409 lookup — use explicit `deleted_at` and `Save::query()` without global scope for uniqueness checks. Listing uses `whereNull('deleted_at')`.

- [ ] **Step 4: Controller**

POST: validate `id` uuid, `url` required|url|max:2048, `title` required|string. If save exists for this user, return it 200. If exists for other user, 409. Else create with `content_status=pending`.

GET: `Save::query()->where('user_id', $user->id)->whereNull('deleted_at')->orderByDesc('created_at')`. Optional `updated_since` filter if query present.

DELETE: find including tombstones. If missing, 404. If already deleted, 204. Else set `deleted_at = now()`, 204.

JSON resource: `id, url, title, content_status, created_at, updated_at`.

- [ ] **Step 5: Run tests**

```bash
cd backend && php artisan test --filter=SaveApiTest
```

Expected: PASS. Then run full `php artisan test`. Expected: all PASS.

---

### Task 4: Flutter domain + theme

**Files:**
- Create: `mobile/lib/domain/models/save.dart`, `mobile/lib/ui/core/theme/later_theme.dart`, `mobile/test/later_theme_test.dart`
- Modify: `mobile/pubspec.yaml` (flutter_riverpod, dio, drift, drift_flutter, sqlite3_flutter_libs, path_provider, flutter_secure_storage, shared_preferences, uuid, go_router or no router — use Navigator 2 / simple `home:` first)

**Interfaces:**
- Produces: `enum SyncStatus { pendingSync, synced, syncFailed }`, `enum ContentStatus { pending, ready, failed }`, `class SaveItem` with `id, url, title, contentStatus, syncStatus, syncError, deletedAt, createdAt, updatedAt`, `LaterTheme.light()` / `LaterTheme.dark()` with canvas `#F7F6F3` / `#1C1C1A`

- [ ] **Step 1: Failing theme test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/core/theme/later_theme.dart';

void main() {
  test('light canvas is warm off-white not pure white', () {
    final theme = LaterTheme.light();
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F6F3));
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
  });

  test('dark canvas is off-black not pure black', () {
    final theme = LaterTheme.dark();
    expect(theme.scaffoldBackgroundColor, const Color(0xFF1C1C1A));
    expect(theme.scaffoldBackgroundColor, isNot(Colors.black));
  });
}
```

- [ ] **Step 2: Run to fail**

```bash
cd mobile && flutter test test/later_theme_test.dart
```

Expected: FAIL compile (library missing).

- [ ] **Step 3: Implement LaterTheme.light/dark** with spec tokens, 8px `BorderRadius`, no elevation. `ColorScheme.fromSeed` is forbidden if it shifts tokens — set `ColorScheme` fields explicitly.

- [ ] **Step 4: Re-run test** — PASS.

---

### Task 5: Save repository writes Drift before HTTP (TDD)

**Files:**
- Create: Drift tables + `SaveRepository.create(url)` 
- Test: `mobile/test/save_repository_test.dart`

**Interfaces:**
- Consumes: `SaveItem`, `ApiClient.createSave` that can throw
- Produces: `Future<SaveItem> SaveRepository.addUrl(String url)` — validates http(s), inserts local `pendingSync` first, then POST, then `synced` or `syncFailed`

- [ ] **Step 1: Failing test** — use in-memory Drift (`NativeDatabase.memory()`). Fake Dio that always throws. After `addUrl('https://example.com')`, query local DB: one row, `syncStatus == syncFailed`, url stored.

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement insert-then-HTTP.** Invalid url throws `FormatException('That isn’t a URL.')` and writes nothing.

- [ ] **Step 4: Tests PASS** including invalid URL writes zero rows.

---

### Task 6: Screens

**Files:** login, list, settings as in the spec. Widget tests: paste shows in list without HTTP; theme toggle rebuilds scaffold color.

**Interfaces:**
- `SettingsRepository`: `apiBaseUrl`, `ThemeMode`
- `AuthRepository.login(email, password)` stores token
- List `SavesController` watches Drift

- [ ] Login widget: Later wordmark, fields, Log in, Server link.
- [ ] List: paste + Add, empty copy, sync chip, retry, swipe delete, gear.
- [ ] Settings: API URL, System/Light/Dark, Log out (only if logged in).
- [ ] iOS `Info.plist` `NSAllowsArbitraryLoads` or `NSExceptionDomains` for local IPs in Debug. Prefer `NSAppTransportSecurity` → `NSAllowsLocalNetworking` = true.

- [ ] **Widget test:** pump SavesScreen with fake repo that returns immediately; enter URL; expect text on screen.

- [ ] **Widget test:** MaterialApp `themeMode: ThemeMode.dark` uses `#1C1C1A`.

---

### Task 7: End-to-end host check

- [ ] `docker compose up -d postgres redis` (and backend if Dockerfile exists)
- [ ] `cd backend && php artisan migrate --seed && php artisan test`
- [ ] `cd mobile && flutter test && flutter analyze`
- [ ] Manual: `php artisan serve --host=0.0.0.0 --port=8080`, run iOS sim, login `you@local.test` / `password`, paste `https://example.com`, row appears.

## Spec coverage

| Spec section | Task |
|---|---|
| Auth login/logout | 2 |
| Saves UUID/idempotent/tombstone | 3 |
| Drift first | 5 |
| Three screens + theme | 4, 6 |
| Docker postgres/redis :8080 | 1, 7 |
| iOS HTTP debug | 6 |
| Seeded user | 2 |
| No parser/collections/register | all |

## Type names

- Dart: `SaveItem`, `SyncStatus.pendingSync|synced|syncFailed`, `ContentStatus.pending`
- PHP: `App\Models\Save`, `content_status` string `pending`
- JSON save: `id`, `url`, `title`, `content_status`, `created_at`, `updated_at`
