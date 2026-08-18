<?php

namespace Tests\Feature;

use App\Models\Collection;
use App\Models\Save;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Str;
use Tests\TestCase;

class CollectionApiTest extends TestCase
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

    public function test_rejects_unauthenticated_collection_list(): void
    {
        $this->getJson('/api/collections')->assertUnauthorized();
    }

    public function test_creates_and_lists_collections(): void
    {
        $this->authUser();
        $id = (string) Str::uuid();

        $this->postJson('/api/collections', [
            'id' => $id,
            'name' => 'Recipes',
        ])->assertOk()
            ->assertJsonPath('id', $id)
            ->assertJsonPath('name', 'Recipes');

        $this->getJson('/api/collections')
            ->assertOk()
            ->assertJsonPath('0.id', $id);
    }

    public function test_renames_a_collection(): void
    {
        $user = $this->authUser();
        $collection = Collection::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'name' => 'Old',
        ]);

        $this->patchJson("/api/collections/{$collection->id}", [
            'name' => 'New',
        ])->assertOk()->assertJsonPath('name', 'New');
    }

    public function test_deleting_a_collection_unfiles_saves(): void
    {
        $user = $this->authUser();
        $collection = Collection::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'name' => 'Recipes',
        ]);
        $save = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
            'content_status' => 'pending',
            'collection_id' => $collection->id,
        ]);

        $this->deleteJson("/api/collections/{$collection->id}")->assertNoContent();
        $this->assertDatabaseMissing('collections', ['id' => $collection->id]);
        $this->assertDatabaseHas('saves', [
            'id' => $save->id,
            'collection_id' => null,
        ]);
    }

    public function test_filters_saves_by_collection_search_and_status(): void
    {
        $user = $this->authUser();
        $recipes = Collection::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'name' => 'Recipes',
        ]);
        $peach = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/peach',
            'title' => 'Grilled peaches',
            'content_status' => 'ready',
            'collection_id' => $recipes->id,
        ]);
        Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/other',
            'title' => 'Something else',
            'content_status' => 'pending',
        ]);

        $this->getJson('/api/saves?q=peach')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $peach->id);

        $this->getJson('/api/saves?collection_id='.$recipes->id)
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $peach->id);

        $this->getJson('/api/saves?unfiled=1')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.title', 'Something else');

        $this->getJson('/api/saves?content_status=ready')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $peach->id);
    }

    public function test_moves_a_save_into_a_collection(): void
    {
        $user = $this->authUser();
        $collection = Collection::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'name' => 'Recipes',
        ]);
        $save = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://example.com/x',
            'title' => 'https://example.com/x',
            'content_status' => 'pending',
        ]);

        $this->patchJson("/api/saves/{$save->id}", [
            'collection_id' => $collection->id,
        ])->assertOk()->assertJsonPath('collection_id', $collection->id);

        $this->patchJson("/api/saves/{$save->id}", [
            'collection_id' => null,
        ])->assertOk()->assertJsonPath('collection_id', null);
    }
}
