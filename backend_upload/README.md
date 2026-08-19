# Hostinger Upload Instructions for `later-dz.site`

Everything in this `backend_upload/` folder is ready to be uploaded to Hostinger.

---

### Folder Overview:

- **`later_api/`** : Contains all backend core files, database (`database.sqlite`), configuration, and `.env`.
- **`public_html/`** : Contains the web root files (`index.php`, `.htaccess`, `robots.txt`).

---

### How to Upload via Hostinger File Manager:

1. **Upload `later_api`**:
   - In Hostinger File Manager, go to your home root: `/home/uXXXXX/` (or inside `/domains/later-dz.site/`).
   - Upload the `later_api` folder here.
   - *Ensure it is located at the same level as `public_html` or directly in your home directory.*

2. **Upload `public_html`**:
   - Open your website's `public_html` folder (`/domains/later-dz.site/public_html/`).
   - Upload the contents of `backend_upload/public_html/` directly inside `public_html`.

3. **Install Dependencies (`vendor/`)**:
   - **Option A (SSH)**: Open SSH Terminal in Hostinger and run:
     ```bash
     cd later_api
     composer install --no-dev --optimize-autoloader
     ```
   - **Option B (File Manager upload)**: If you don't have SSH, upload your local `backend/vendor/` folder into `later_api/vendor/`.

4. **Permissions**:
   - In Hostinger File Manager, ensure write permissions (`chmod 775` or `chmod 777`) for:
     - `later_api/database/` & `later_api/database/database.sqlite`
     - `later_api/storage/`
     - `later_api/bootstrap/cache/`

5. **Configure Gemini API Key**:
   - Edit `later_api/.env` and paste your `GEMINI_API_KEY=...`.
