<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class GeminiService
{
    public function analyze(string $url, string $title, ?string $rawContent = null): array
    {
        $apiKey = config('services.gemini.key');
        if (empty($apiKey)) {
            return $this->fallback($url, $title);
        }

        $prompt = <<<PROMPT
Analyze this saved bookmark for a Save-for-Later app:
URL: {$url}
Given Title: {$title}

If the Given Title is a raw URL, generic word like "Instagram" or "Login", generate a clean descriptive title.
Return ONLY a raw JSON object (with no backticks, no markdown) with exact keys:
{
  "title": "Clean, descriptive human title for this link",
  "summary": "Concise 1-2 sentence description of this link",
  "category": "One of: Article, Recipe, Video, Place, Workout, Product, Tool, Post, Link",
  "tags": ["tag1", "tag2", "tag3"]
}
PROMPT;

        try {
            $endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent';
            $response = Http::timeout(10)
                ->withoutVerifying()
                ->withQueryParameters(['key' => $apiKey])
                ->post($endpoint, [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt]
                            ]
                        ]
                    ]
                ]);

            if ($response->successful()) {
                $text = $response->json('candidates.0.content.parts.0.text') ?? '';
                $clean = trim(str_replace(['```json', '```'], '', $text));
                $data = json_decode($clean, true);

                if (is_array($data) && isset($data['summary'])) {
                    return [
                        'title' => !empty($data['title']) ? (string) $data['title'] : $title,
                        'summary' => (string) $data['summary'],
                        'category' => (string) ($data['category'] ?? 'Link'),
                        'tags' => is_array($data['tags'] ?? null) ? $data['tags'] : [],
                    ];
                }
            }
        } catch (Throwable $e) {
            Log::warning('Gemini API call failed: ' . $e->getMessage());
        }

        return $this->fallback($url, $title);
    }

    private function fallback(string $url, string $title): array
    {
        $host = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
        $category = 'Link';

        if (str_contains($host, 'youtube') || str_contains($host, 'tiktok') || str_contains($host, 'vimeo')) {
            $category = 'Video';
        } elseif (str_contains($url, 'recipe') || str_contains($title, 'recipe') || str_contains($title, 'cook')) {
            $category = 'Recipe';
        } elseif (str_contains($host, 'instagram') || str_contains($host, 'twitter') || str_contains($host, 'x.com')) {
            $category = 'Post';
        }

        return [
            'summary' => "Saved link from {$host}: {$title}",
            'category' => $category,
            'tags' => [strtolower($category), $host],
        ];
    }
}
