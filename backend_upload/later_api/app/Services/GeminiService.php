<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class GeminiService
{
    public function analyze(string $url, string $title, ?string $description = null, array $existingCollections = []): array
    {
        $apiKey = config('services.gemini.key');
        if (empty($apiKey)) {
            return $this->fallback($url, $title, $description, $existingCollections);
        }

        $collectionsList = !empty($existingCollections)
            ? implode(', ', array_map(fn($c) => '"' . trim($c) . '"', $existingCollections))
            : 'None';

        $descContext = !empty($description) ? "Page Description / Caption: {$description}\n" : '';

        $prompt = <<<PROMPT
You are an expert AI bookmark curator, smart categorizer, and title editor for Later (a modern save-for-later app).
Analyze this saved link:
URL: {$url}
Raw Title: {$title}
{$descContext}User's Existing Folders/Collections: [{$collectionsList}]

1. SMART CLEAN REWRITTEN TITLE (Crucial):
- Completely rewrite the title into an ultra-short, highly descriptive, punchy headline (2 to 5 words, strictly maximum 40 characters).
- Extract the real specific subject, dish, topic, or product entity.
- NEVER include website branding, author names, channels, "@handles", "on TikTok", "Instagram video by...", clickbait phrases, emojis, or punctuation fluff.
- Examples:
  * Instagram reel of a pasta recipe -> "Garlic Butter Parmesan Pasta" (NEVER "Watch on Instagram" or "@chef's reel")
  * TikTok gym video -> "15-Min Dumbbell Shoulder Workout" (NEVER "Do this every day #fyp")
  * Amazon link -> "Sony WH-1000XM5 Headphones" (NEVER "Amazon.com: Sony WH-1000XM5 Noise Canceling...")
  * YouTube tutorial -> "Flutter Riverpod 3.0 Guide" (NEVER "Learn Flutter in 20 minutes!! (Full Course)")
  * Arabic cooking reel -> "طريقة عمل البيتزا الإيطالية"
  * Travel article -> "Amalfi Coast 3-Day Itinerary"
- Keep the language of the title identical to the language of the content (Arabic for Arabic content, English for English, etc.).

2. SEMANTIC TOPIC CATEGORIZATION & SMART FOLDER:
- Categorize by SUBJECT MATTER, not media format! A cooking video is "Recipes", NOT "Video". A fitness TikTok is "Fitness", NOT "Video". An outfit haul is "Fashion", NOT "Product".
- Primary Taxonomy:
  * "Recipes" (Cooking, baking, meals, cocktails, restaurant dishes)
  * "Tech" (Coding, programming, AI, gadgets, software development)
  * "Fitness" (Workouts, exercises, gym routines, health, yoga)
  * "Design" (UI/UX, architecture, typography, graphic design, 3D)
  * "Shopping" (Products to buy, wishlist, fashion, sneakers, gear)
  * "Travel" (Destinations, hotels, itineraries, city guides, spots)
  * "Finance" (Investing, crypto, budgeting, business, real estate)
  * "Books" (Book recommendations, literature, reading lists)
  * "Articles" (Longform essays, news, journalism, deep-dives)
  * "Inspiration" (Ideas, quotes, aesthetic collections, creative concepts)
  * "Entertainment" (Movies, music, gaming, comedy)
  * "Link" (General/unclassified)

- FOLDER MATCHING RULE:
  * If one of the User's Existing Folders matches this content (e.g. user has "Cooking" or "Dev"), set "collection" to that EXACT existing folder name.
  * If none of the user's existing folders fit, set "collection" to the best fitting category name from the taxonomy above (e.g. "Recipes", "Tech", "Fitness", "Shopping").

3. CONCISE AI SUMMARY:
- 1 concise, high-signal sentence (under 120 characters) explaining what the user will find when they open this link.

4. TARGETED TAGS:
- 3 to 5 lowercase keyword tags (e.g., ["pasta", "italian", "dinner"]).

Return ONLY a valid raw JSON object (strictly no markdown formatting, no code blocks):
{
  "title": "Short Entity Title (2-5 words)",
  "summary": "1 concise high-signal summary sentence.",
  "category": "Selected Category",
  "collection": "Matched or Suggested Folder Name",
  "tags": ["tag1", "tag2", "tag3"]
}
PROMPT;

        try {
            $endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
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
                $parts = $response->json('candidates.0.content.parts') ?? [];
                $text = '';
                foreach ($parts as $part) {
                    if (!empty($part['text'])) {
                        $text .= $part['text'] . "\n";
                    }
                }
                
                $data = null;
                if (preg_match('/\{[\s\S]*\}/u', $text, $matches)) {
                    $data = json_decode($matches[0], true);
                }

                if (is_array($data) && isset($data['summary'])) {
                    return [
                        'title' => !empty($data['title']) ? (string) $data['title'] : $this->condenseTitle($title, $url),
                        'summary' => (string) $data['summary'],
                        'category' => (string) ($data['category'] ?? 'Link'),
                        'collection' => !empty($data['collection']) ? (string) $data['collection'] : (string) ($data['category'] ?? 'Link'),
                        'tags' => is_array($data['tags'] ?? null) ? $data['tags'] : [],
                    ];
                }
            }
        } catch (Throwable $e) {
            Log::warning('Gemini API call failed: ' . $e->getMessage());
        }

        return $this->fallback($url, $title, $description, $existingCollections);
    }

    private function fallback(string $url, string $title, ?string $description = null, array $existingCollections = []): array
    {
        $host = strtolower(parse_url($url, PHP_URL_HOST) ?? '');
        $combined = strtolower("{$url} {$title} " . ($description ?? ''));
        $category = 'Link';

        if (str_contains($combined, 'recipe') || str_contains($combined, 'cook') || str_contains($combined, 'food') || str_contains($combined, 'kitchen') || str_contains($combined, 'baking')) {
            $category = 'Recipes';
        } elseif (str_contains($combined, 'workout') || str_contains($combined, 'fitness') || str_contains($combined, 'gym') || str_contains($combined, 'exercise')) {
            $category = 'Fitness';
        } elseif (str_contains($host, 'github') || str_contains($host, 'gitlab') || str_contains($host, 'stackoverflow') || str_contains($combined, 'flutter') || str_contains($combined, 'react') || str_contains($combined, 'laravel') || str_contains($combined, 'coding')) {
            $category = 'Tech';
        } elseif (str_contains($host, 'figma') || str_contains($host, 'dribbble') || str_contains($host, 'behance') || str_contains($combined, 'ui/ux')) {
            $category = 'Design';
        } elseif (str_contains($host, 'amazon') || str_contains($host, 'aliexpress') || str_contains($combined, 'shop') || str_contains($combined, 'buy') || str_contains($combined, 'product')) {
            $category = 'Shopping';
        } elseif (str_contains($combined, 'travel') || str_contains($combined, 'hotel') || str_contains($combined, 'flight') || str_contains($combined, 'destination')) {
            $category = 'Travel';
        } elseif (str_contains($host, 'youtube') || str_contains($host, 'tiktok') || str_contains($host, 'vimeo')) {
            $category = 'Entertainment';
        } elseif (str_contains($host, 'instagram') || str_contains($host, 'twitter') || str_contains($host, 'x.com') || str_contains($host, 'reddit')) {
            $category = 'Articles';
        }

        // Try to match existing collections
        $matchedCollection = $category;
        foreach ($existingCollections as $existing) {
            if (strcasecmp($existing, $category) === 0) {
                $matchedCollection = $existing;
                break;
            }
        }

        return [
            'title' => $this->condenseTitle($title, $url),
            'summary' => "Saved link from {$host}: {$title}",
            'category' => $category,
            'collection' => $matchedCollection,
            'tags' => [strtolower($category), $host],
        ];
    }

    private function condenseTitle(string $title, string $url): string
    {
        $clean = preg_replace('/(\s*[-|–—:]\s*(YouTube|Instagram|TikTok|Twitter|X|Facebook|Reddit|Medium|GitHub|Amazon)).*$/i', '', $title);
        $clean = preg_replace('/https?:\/\/[^\s]+/i', '', $clean);
        $clean = trim($clean);

        if (empty($clean)) {
            return parse_url($url, PHP_URL_HOST) ?: $url;
        }

        // Limit to first 5 words if very long
        $words = preg_split('/\s+/u', $clean, -1, PREG_SPLIT_NO_EMPTY);
        if ($words !== false && count($words) > 5) {
            return implode(' ', array_slice($words, 0, 5));
        }

        return $clean;
    }
}
