# Deploying Later Backend to Hostinger Shared Hosting (`later-dz.site`) using SQLite

Using **SQLite** makes deployment easier on Hostinger because you don't need to configure a separate MySQL database or manage credentials.

---

## 1. Prepare Locally

### A. Install Production Dependencies
Run in the `backend/` directory:
```bash
composer install --no-dev --optimize-autoloader
```

### B. Generate Application Key (if not already set)
```bash
php artisan key:generate --show
```
*Save this key for your production `.env`.*

---

## 2. Directory Structure on Hostinger

Shared hosting has a `public_html/` root. For Laravel security, keep your SQLite database and core files outside `public_html`.

Recommended structure in your Hostinger File Manager / SSH:
```text
/home/u123456789/
├── later_api/                <-- Put all Laravel project files here (including database/database.sqlite)
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   │   └── database.sqlite   <-- SQLite database file
│   ├── routes/
│   ├── storage/
│   ├── vendor/
│   ├── .env
│   └── artisan
└── domains/later-dz.site/public_html/   <-- Put contents of Laravel's `public/` folder here
    ├── .htaccess
    ├── index.php
    ├── favicon.ico
    └── robots.txt
```

---

## 3. Hostinger Setup Steps

### Step 1: Upload Files
1. Zip the `backend/` folder (excluding `tests/`, `node_modules/`, `.git/`).
2. In Hostinger File Manager:
   - Extract the project into `/home/uXXXXX/later_api/` (outside `public_html`).
   - Move or copy everything from `later_api/public/` into `domains/later-dz.site/public_html/`.

### Step 2: Ensure SQLite File & Permissions
1. In `later_api/database/`, ensure `database.sqlite` exists (create an empty file named `database.sqlite` if not present).
2. Set write permissions (`chmod 775` or `chmod 777` in File Manager) for:
   - `later_api/database/` (directory)
   - `later_api/database/database.sqlite` (file)
   - `later_api/storage/` (directory)
   - `later_api/bootstrap/cache/` (directory)

### Step 3: Update `public_html/index.php`
Edit `domains/later-dz.site/public_html/index.php` to point to `later_api`:
```php
// Change lines:
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';

// TO:
require __DIR__.'/../../later_api/vendor/autoload.php';
$app = require_once __DIR__.'/../../later_api/bootstrap/app.php';
```

### Step 4: Configure `.env`
In `later_api/.env`, copy from [`.env.production.example`](file:///c:/development/alboClone/alboClone/backend/.env.production.example):
```env
APP_NAME=Later
APP_ENV=production
APP_KEY=base64:... (your app key)
APP_DEBUG=false
APP_URL=https://later-dz.site

DB_CONNECTION=sqlite

GEMINI_API_KEY=your_gemini_api_key
```

### Step 5: Run Migrations & Cache Config (via SSH)
In Hostinger SSH Terminal:
```bash
cd /home/uXXXXX/later_api
php artisan migrate --force
php artisan config:cache
php artisan route:cache
```

*(Note: If you don't have SSH, you can upload your pre-migrated `database.sqlite` directly from your local `backend/database/database.sqlite` via File Manager!)*

---

## 4. Verification

Test the deployment:
- `https://later-dz.site/up` (Health check, returns 200 OK)
- `https://later-dz.site/api/saves` (Returns `401 Unauthorized` unauthenticated, proving API router is live)
