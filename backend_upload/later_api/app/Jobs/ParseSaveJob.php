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
                // Fetch user's existing collections
                $userCollections = \App\Models\Collection::query()
                    ->where('user_id', $save->user_id)
                    ->pluck('name', 'id')
                    ->toArray();

                $collectionNames = array_values($userCollections);

                // AI Enrichment with Gemini
                $aiData = $gemini->analyze(
                    url: $save->url,
                    title: $initialTitle,
                    description: $preview->description,
                    existingCollections: $collectionNames,
                );

                if (!empty($aiData['title'])) {
                    $save->title = $aiData['title'];
                }
                $save->ai_summary = $aiData['summary'] ?? null;
                $save->category = $aiData['category'] ?? 'Link';
                $save->ai_tags = $aiData['tags'] ?? [];

                // Smart AI Auto-Folder: If unfiled and collection/category is meaningful
                if ($save->collection_id === null) {
                    $targetFolder = trim($aiData['collection'] ?? $aiData['category'] ?? '');
                    if (!empty($targetFolder) && !in_array(strtolower($targetFolder), ['link', 'other', 'general', 'none'], true)) {
                        // Check if matches an existing user collection (case-insensitive)
                        $existingId = null;
                        foreach ($userCollections as $colId => $colName) {
                            if (strcasecmp((string)$colName, $targetFolder) === 0) {
                                $existingId = $colId;
                                break;
                            }
                        }

                        if ($existingId !== null) {
                            $save->collection_id = $existingId;
                        } else {
                            $collection = \App\Models\Collection::create([
                                'id' => (string) \Illuminate\Support\Str::uuid(),
                                'user_id' => $save->user_id,
                                'name' => ucfirst($targetFolder),
                            ]);
                            $save->collection_id = $collection->id;
                        }
                    }
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
