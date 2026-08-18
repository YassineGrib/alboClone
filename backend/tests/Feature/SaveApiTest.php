<?php

namespace Tests\Feature;

use App\Models\Save;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Str;
use Tests\TestCase;

class SaveApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Bus::fake();
    }

    private function authUser(): User
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        return $user;
    }

    public function test_rejects_unauthenticated_listing(): void
    {
        $this->getJson('/api/saves')->assertUnauthorized();
    }

    public function test_stores_a_save_with_the_client_uuid(): void
    {
        $this->authUser();
        $id = (string) Str::uuid();

        $this->postJson('/api/saves', [
            'id' => $id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
        ])->assertOk()
            ->assertJsonPath('id', $id)
            ->assertJsonPath('content_status', 'pending');

        $this->assertDatabaseHas('saves', [
            'id' => $id,
            'url' => 'https://example.com/x',
        ]);
    }

    public function test_is_idempotent_for_the_same_uuid_and_user(): void
    {
        $this->authUser();
        $id = (string) Str::uuid();
        $payload = [
            'id' => $id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
        ];

        $this->postJson('/api/saves', $payload)->assertOk();
        $this->postJson('/api/saves', $payload)->assertOk();

        $this->assertSame(1, Save::query()->count());
    }

    public function test_returns_409_when_uuid_belongs_to_another_user(): void
    {
        $id = (string) Str::uuid();
        $owner = User::factory()->create();
        Save::query()->create([
            'id' => $id,
            'user_id' => $owner->id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
            'content_status' => 'pending',
        ]);

        $this->authUser();
        $this->postJson('/api/saves', [
            'id' => $id,
            'url' => 'https://example.com/y',
            'title' => 'https://example.com/y',
        ])->assertStatus(409);
    }

    public function test_lists_alive_saves_newest_first_and_omits_tombstones(): void
    {
        $user = $this->authUser();
        $old = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/old',
            'title' => 'https://example.com/old',
            'content_status' => 'pending',
            'created_at' => now()->subDay(),
        ]);
        $new = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/new',
            'title' => 'https://example.com/new',
            'content_status' => 'pending',
        ]);
        Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/gone',
            'title' => 'https://example.com/gone',
            'content_status' => 'pending',
            'deleted_at' => now(),
        ]);

        $ids = collect($this->getJson('/api/saves')->assertOk()->json())->pluck('id')->all();

        $this->assertSame([$new->id, $old->id], $ids);
    }

    public function test_tombstones_on_delete_and_second_delete_is_204(): void
    {
        $user = $this->authUser();
        $id = (string) Str::uuid();
        Save::query()->create([
            'id' => $id,
            'user_id' => $user->id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
            'content_status' => 'pending',
        ]);

        $this->deleteJson("/api/saves/{$id}")->assertNoContent();
        $this->deleteJson("/api/saves/{$id}")->assertNoContent();
        $this->getJson('/api/saves')->assertOk()->assertExactJson([]);
    }

    public function test_returns_404_when_deleting_an_id_that_never_existed(): void
    {
        $this->authUser();
        $this->deleteJson('/api/saves/'.Str::uuid())->assertNotFound();
    }
}
