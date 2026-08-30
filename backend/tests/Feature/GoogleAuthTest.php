<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_requires_id_token(): void
    {
        $this->postJson('/api/auth/google', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['id_token']);
    }

    public function test_rejects_invalid_token(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response(['error' => 'invalid_token'], 400),
        ]);

        $this->postJson('/api/auth/google', [
            'id_token' => 'invalid-token',
        ])->assertUnauthorized()
          ->assertJson(['message' => 'Invalid Google ID token.']);
    }

    public function test_rejects_audience_mismatch(): void
    {
        Config::set('services.google.client_id', 'expected-client-id.apps.googleusercontent.com');

        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'sub' => 'google-user-123',
                'email' => 'user@gmail.com',
                'email_verified' => 'true',
                'aud' => 'different-client-id.apps.googleusercontent.com',
                'name' => 'Test User',
            ], 200),
        ]);

        $this->postJson('/api/auth/google', [
            'id_token' => 'valid-token-wrong-aud',
        ])->assertUnauthorized()
          ->assertJson(['message' => 'Google Client ID mismatch.']);
    }

    public function test_creates_new_user_and_returns_token(): void
    {
        Config::set('services.google.client_id', 'test-client-id.apps.googleusercontent.com');

        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'sub' => 'google-user-123',
                'email' => 'newgoogleuser@gmail.com',
                'email_verified' => 'true',
                'aud' => 'test-client-id.apps.googleusercontent.com',
                'name' => 'New Google User',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'valid-token',
        ]);

        $response->assertOk()
            ->assertJsonPath('user.email', 'newgoogleuser@gmail.com')
            ->assertJsonStructure(['token', 'user' => ['id', 'email']]);

        $this->assertDatabaseHas('users', [
            'email' => 'newgoogleuser@gmail.com',
            'google_id' => 'google-user-123',
        ]);
    }

    public function test_logs_in_existing_user_and_updates_google_id(): void
    {
        Config::set('services.google.client_id', 'test-client-id.apps.googleusercontent.com');

        $user = User::factory()->create([
            'email' => 'existing@gmail.com',
            'google_id' => null,
        ]);

        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'sub' => 'google-user-456',
                'email' => 'existing@gmail.com',
                'email_verified' => 'true',
                'aud' => 'test-client-id.apps.googleusercontent.com',
                'name' => 'Existing User',
            ], 200),
        ]);

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'valid-token',
        ]);

        $response->assertOk()
            ->assertJsonPath('user.id', $user->id)
            ->assertJsonPath('user.email', 'existing@gmail.com');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'google_id' => 'google-user-456',
        ]);
    }
}
