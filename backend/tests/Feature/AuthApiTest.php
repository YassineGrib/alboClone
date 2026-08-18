<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_logs_in_with_email_and_password_and_returns_a_token(): void
    {
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

        $this->assertSame($user->id, $response->json('user.id'));
    }

    public function test_rejects_bad_credentials_with_422(): void
    {
        User::factory()->create([
            'email' => 'you@local.test',
            'password' => 'password',
        ]);

        $this->postJson('/api/login', [
            'email' => 'you@local.test',
            'password' => 'nope',
        ])->assertUnprocessable();
    }

    public function test_logs_out_the_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/logout')
            ->assertNoContent();
    }
}
