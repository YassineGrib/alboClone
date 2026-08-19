<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class LinkPreviewFetcher
{
    public function fetch(string $url): LinkPreview
    {
        $oembed = $this->oembedEndpoint($url);
        if ($oembed !== null) {
            $response = Http::timeout(8)
                ->withoutVerifying()
                ->acceptJson()
                ->get($oembed);

            if ($response->successful()) {
                $preview = LinkPreview::fromOEmbed($response->json() ?? []);
                if ($preview->title !== null || $preview->imageUrl !== null) {
                    return $preview;
                }
            }
        }

        $response = Http::timeout(8)
            ->withoutVerifying()
            ->withHeaders([
                'User-Agent' => 'LaterBot/1.0 (+https://later.local)',
                'Accept' => 'text/html,application/xhtml+xml',
            ])
            ->get($url);

        if ($response->successful()) {
            return LinkPreview::fromHtml((string) $response->body(), $url);
        }

        throw new \RuntimeException("Failed to fetch link: HTTP {$response->status()}");
    }

    private function oembedEndpoint(string $url): ?string
    {
        $host = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
        $host = str_starts_with($host, 'www.') ? substr($host, 4) : $host;
        $encoded = urlencode($url);

        return match (true) {
            $host === 'youtube.com', $host === 'youtu.be', $host === 'm.youtube.com' => 'https://www.youtube.com/oembed?format=json&url='.$encoded,
            $host === 'tiktok.com', str_ends_with($host, '.tiktok.com') => 'https://www.tiktok.com/oembed?url='.$encoded,
            $host === 'vimeo.com' => 'https://vimeo.com/api/oembed.json?url='.$encoded,
            default => null,
        };
    }
}
