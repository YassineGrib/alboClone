<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_registers_a_new_user_and_returns_token_and_user(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Yassine',
            'email' => 'newuser@example.com',
            'password' => 'secret123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('user.name', 'Yassine')
            ->assertJsonPath('user.email', 'newuser@example.com')
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);

        $this->assertDatabaseHas('users', [
            'email' => 'newuser@example.com',
            'name' => 'Yassine',
        ]);
    }

    public function test_register_rejects_duplicate_email_with_422(): void
    {
        User::factory()->create([
            'email' => 'existing@example.com',
        ]);

        $this->postJson('/api/register', [
            'name' => 'Another Name',
            'email' => 'existing@example.com',
            'password' => 'secret123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_register_requires_name_email_and_valid_password(): void
    {
        $this->postJson('/api/register', [
            'name' => '',
            'email' => 'not-an-email',
            'password' => '123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password']);
    }

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

    public function test_deletes_account_and_user_data(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withToken($token)
            ->deleteJson('/api/account')
            ->assertNoContent();

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }
}
