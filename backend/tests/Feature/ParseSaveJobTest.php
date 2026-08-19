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
