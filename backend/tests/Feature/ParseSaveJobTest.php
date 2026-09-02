<?php

namespace Tests\Feature;

use App\Jobs\ParseSaveJob;
use App\Models\Save;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class ParseSaveJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_marks_save_ready_with_og_tags(): void
    {
        Http::fake([
            'https://example.com/recipe' => Http::response(
                '<html><head><meta property="og:title" content="Peaches"><meta property="og:image" content="https://cdn.example.com/p.jpg"></head></html>',
                200,
            ),
        ]);

        $save = $this->makeSave('https://example.com/recipe');

        ParseSaveJob::dispatchSync($save->id, aiEnabled: false);

        $save->refresh();
        $this->assertSame('ready', $save->content_status);
        $this->assertSame('Peaches', $save->title);
        $this->assertSame('https://cdn.example.com/p.jpg', $save->image_url);
    }

    public function test_marks_save_failed_when_the_page_cannot_be_fetched(): void
    {
        Http::fake([
            'https://example.com/gone' => Http::response('nope', 404),
        ]);

        $save = $this->makeSave('https://example.com/gone');

        ParseSaveJob::dispatchSync($save->id, aiEnabled: false);

        $save->refresh();
        $this->assertSame('failed', $save->content_status);
        $this->assertSame('https://example.com/gone', $save->title);
    }

    public function test_uses_youtube_oembed_when_available(): void
    {
        Http::fake([
            'https://www.youtube.com/oembed*' => Http::response([
                'title' => 'A video',
                'thumbnail_url' => 'https://i.ytimg.com/vi/abc/hqdefault.jpg',
            ], 200),
        ]);

        $save = $this->makeSave('https://www.youtube.com/watch?v=abc');

        ParseSaveJob::dispatchSync($save->id, aiEnabled: false);

        $save->refresh();
        $this->assertSame('ready', $save->content_status);
        $this->assertSame('A video', $save->title);
        $this->assertSame('https://i.ytimg.com/vi/abc/hqdefault.jpg', $save->image_url);
    }

    public function test_ai_creates_smart_topic_collection_and_clean_title(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            'https://instagram.com/reel/123' => Http::response(
                '<html><head><meta property="og:title" content="Watch this video on Instagram by @chef_john: best creamy garlic pasta recipe ever!!"><meta property="og:description" content="Quick 15 min dinner idea with parmesan and garlic."></head></html>',
                200,
            ),
            'https://generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => json_encode([
                                        'title' => 'Creamy Garlic Parmesan Pasta',
                                        'summary' => 'A fast 15-minute Italian dinner recipe with garlic and parmesan.',
                                        'category' => 'Recipes',
                                        'collection' => 'Recipes',
                                        'tags' => ['pasta', 'dinner', 'italian'],
                                    ]),
                                ],
                            ],
                        ],
                    ],
                ],
            ], 200),
        ]);

        $save = $this->makeSave('https://instagram.com/reel/123');

        ParseSaveJob::dispatchSync($save->id, aiEnabled: true);

        $save->refresh();
        $this->assertSame('ready', $save->content_status);
        $this->assertSame('Creamy Garlic Parmesan Pasta', $save->title);
        $this->assertSame('Recipes', $save->category);
        $this->assertNotNull($save->collection_id);
        $this->assertSame('Recipes', $save->collection->name);
    }

    public function test_ai_matches_existing_user_collection(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        $user = User::factory()->create();
        $existingCollection = \App\Models\Collection::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'name' => 'Meals & Cooking',
        ]);

        $save = Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => 'https://tiktok.com/@chef/video/456',
            'title' => 'TikTok video',
            'content_status' => 'pending',
        ]);

        Http::fake([
            'https://tiktok.com/@chef/video/456' => Http::response(
                '<html><head><meta property="og:title" content="Viral Crispy Chicken Burger Recipe"><meta property="og:description" content="Homemade crispy burger"></head></html>',
                200,
            ),
            'https://generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => json_encode([
                                        'title' => 'Crispy Chicken Burger',
                                        'summary' => 'Step by step guide to making a crispy chicken burger.',
                                        'category' => 'Recipes',
                                        'collection' => 'Meals & Cooking',
                                        'tags' => ['burger', 'chicken', 'recipe'],
                                    ]),
                                ],
                            ],
                        ],
                    ],
                ],
            ], 200),
        ]);

        ParseSaveJob::dispatchSync($save->id, aiEnabled: true);

        $save->refresh();
        $this->assertSame('Crispy Chicken Burger', $save->title);
        $this->assertSame('Recipes', $save->category);
        // It must link to the existing collection, NOT create a duplicate one
        $this->assertSame($existingCollection->id, $save->collection_id);
        $this->assertSame('Meals & Cooking', $save->collection->name);
    }


    private function makeSave(string $url): Save
    {
        $user = User::factory()->create();

        return Save::query()->create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'url' => $url,
            'title' => $url,
            'content_status' => 'pending',
        ]);
    }
}
