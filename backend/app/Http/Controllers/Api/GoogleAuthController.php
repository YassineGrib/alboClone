<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class GoogleAuthController extends Controller
{
    public function googleLogin(Request $request): JsonResponse
    {
        $request->validate([
            'id_token' => ['required', 'string'],
        ]);

        $idToken = $request->string('id_token')->toString();

        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if ($response->failed()) {
            return response()->json([
                'message' => 'Invalid Google ID token.',
            ], 401);
        }

        $payload = $response->json();

        $expectedClientId = Config::get('services.google.client_id');
        if ($expectedClientId && isset($payload['aud']) && $payload['aud'] !== $expectedClientId) {
            return response()->json([
                'message' => 'Google Client ID mismatch.',
            ], 401);
        }

        $isEmailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        if (! $isEmailVerified) {
            return response()->json([
                'message' => 'Google email is not verified.',
            ], 401);
        }

        $googleId = $payload['sub'] ?? null;
        $email = $payload['email'] ?? null;
        $name = $payload['name'] ?? explode('@', $email)[0];

        if (! $email || ! $googleId) {
            return response()->json([
                'message' => 'Google profile payload incomplete.',
            ], 401);
        }

        $user = User::query()->where('google_id', $googleId)->first();

        if (! $user) {
            $user = User::query()->where('email', $email)->first();
            if ($user) {
                $user->google_id = $googleId;
                $user->save();
            } else {
                $user = User::create([
                    'id' => (string) Str::uuid(),
                    'name' => $name,
                    'email' => $email,
                    'google_id' => $googleId,
                    'password' => null,
                ]);
            }
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
            ],
        ]);
    }
}
