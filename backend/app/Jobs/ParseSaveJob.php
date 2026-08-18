<?php

namespace App\Jobs;

use App\Models\Save;
use App\Services\GeminiService;
use App\Services\LinkPreviewFetcher;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Throwable;

class ParseSaveJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $saveId, public bool $aiEnabled = true) {}

    public function handle(LinkPreviewFetcher $fetcher, GeminiService $gemini): void
    {
        $save = Save::query()->find($this->saveId);
        if ($save === null || $save->deleted_at !== null) {
            return;
        }

        try {
            $preview = $fetcher->fetch($save->url);
            $initialTitle = $preview->title ?: $save->url;
            $save->title = $initialTitle;
            $save->image_url = $preview->imageUrl;

            if ($this->aiEnabled) {
                // AI Enrichment with Gemini
                $aiData = $gemini->analyze($save->url, $initialTitle);
                if (!empty($aiData['title']) && ($initialTitle === $save->url || in_array(strtolower($initialTitle), ['instagram', 'facebook', 'login', 'tiktok', 'youtube'], true))) {
                    $save->title = $aiData['title'];
                }
                $save->ai_summary = $aiData['summary'] ?? null;
                $save->category = $aiData['category'] ?? 'Link';
                $save->ai_tags = $aiData['tags'] ?? [];

                // Smart AI Auto-Folder: If unfiled and category is meaningful, put in folder
                if ($save->collection_id === null && !empty($save->category) && !in_array(strtolower($save->category), ['link', 'other'], true)) {
                    $collectionName = ucfirst(trim($save->category));
                    $collection = \App\Models\Collection::firstOrCreate(
                        ['user_id' => $save->user_id, 'name' => $collectionName],
                        ['id' => (string) \Illuminate\Support\Str::uuid()]
                    );
                    $save->collection_id = $collection->id;
                }
            } else {
                $save->category = 'Link';
            }

            $save->content_status = 'ready';
            $save->save();
        } catch (Throwable) {
            $save->content_status = 'failed';
            $save->save();
        }
    }
}
