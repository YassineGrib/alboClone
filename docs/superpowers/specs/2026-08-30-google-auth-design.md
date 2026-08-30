# Later — Google Auth Slice Design

**Date:** 2026-08-30  
**Slice:** Google Auth Login (Flutter `google_sign_in` + Laravel `POST /api/auth/google`)  
**Status:** proposed  

---

## 1. Overview & Goal

Enable users to sign in or register in the **Later** app with one tap using Google Sign-In.

---

## 2. Architecture & Flow

```
[Flutter App] 
  └─► GoogleSignIn().signIn() 
        └─► Obtains `idToken` from Google SDK
              └─► POST /api/auth/google { "id_token": "..." }
                    └─► [Laravel Backend]
                          ├─► Verify Google ID token
                          ├─► Find or create User by email/google_id
                          └─► Return Sanctum bearer token
```

---

## 3. Detailed Specifications

### Database Schema (Laravel)
Migration `add_google_id_to_users_table`:
- `google_id`: `string`, nullable, indexed
- `password`: modify column to be nullable for OAuth-created accounts

### Backend API (Laravel)
- **Endpoint:** `POST /api/auth/google`
- **Request Body:**
  ```json
  {
    "id_token": "eyJhbGciOiJSUzI1NiIs..."
  }
  ```
- **Validation & Auth Logic:**
  1. Validate `id_token` is present.
  2. Verify `id_token` signature and claims with Google (sub, email, email_verified).
  3. Locate `User` where `google_id == sub` or `email == token.email`.
  4. Create user if not present (`email`, `name`, `google_id = sub`, `password = null`).
  5. Issue Sanctum token (`$user->createToken('mobile')->plainTextToken`).
  6. Return `200 OK` with `{ "token": "...", "user": { "id": ..., "email": ... } }`.

### Mobile App (Flutter)
- Package: `google_sign_in`
- Repository: `AuthRepository.loginWithGoogle(String idToken)`
- UI: Add "Sign in with Google" button on `LoginScreen` with Google icon & design matching `Later` theme.
- Error handling: Show user-friendly error note if Google Sign-In fails or is canceled.

---

## 4. Verification & Testing

- **Backend (Pest/PHPUnit):** `tests/Feature/GoogleAuthTest.php` with mocked Google token verification service testing user creation, existing user login, and invalid token rejections.
- **Mobile (Flutter):** Unit/widget test for `LoginScreen` and `AuthRepository` with mocked `GoogleSignIn` and API client.
