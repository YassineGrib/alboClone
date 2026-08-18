<?php

namespace App\Jobs;

use App\Models\Save;
use App\Services\LinkPreviewFetcher;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Throwable;

class ParseSaveJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $saveId) {}

    public function handle(LinkPreviewFetcher $fetcher): void
    {
        $save = Save::query()->find($this->saveId);
        if ($save === null || $save->deleted_at !== null) {
            return;
        }

        try {
            $preview = $fetcher->fetch($save->url);
            $save->title = $preview->title ?: $save->url;
            $save->image_url = $preview->imageUrl;
            $save->content_status = 'ready';
            $save->save();
        } catch (Throwable) {
            $save->content_status = 'failed';
            $save->save();
        }
    }
}
