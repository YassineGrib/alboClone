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
You are an expert AI bookmark curator, smart categorizer, and title editor for a premium Save-for-Later application.
Analyze this saved link:
URL: {$url}
Raw Title / Page Context: {$title}

1. SMART SHORT REWRITTEN TITLE (Crucial):
- Completely rewrite the title into an ultra-short, highly descriptive, punchy headline (2 to 4 words, strictly maximum 30 characters).
- Extract ONLY the real core subject or entity of the bookmark.
- NEVER include website branding, author names, channels, "@handles", "on TikTok", "Instagram video by...", clickbait phrases, emojis, or punctuation fluff.
- Examples of short rewrites:
  * "Top 10 Best Productivity Tools and Notion templates you must try in 2026" -> "Productivity Tools"
  * "Watch Gordon Ramsay make the ultimate crispy chicken burger recipe" -> "Crispy Chicken Burger"
  * "Learn Flutter 3.x State Management with Riverpod in 20 minutes" -> "Flutter Riverpod"
  * "كيفية تحضير أشهى بيتزا إيطالية في المنزل بخطوات سهلة" -> "البيتزا الإيطالية"
  * "Nike Air Jordan 1 Retro High OG Men's Shoes - Buy Online" -> "Air Jordan 1 Retro"
- Keep the language of the title identical to the language of the content (Arabic for Arabic content, English for English, etc.).

2. DEEP & ACCURATE CATEGORIZATION:
Classify into the single best specific category from this taxonomy:
- "Tech" (Coding, programming, software, AI, hardware, apps, dev tutorials)
- "Design" (UI/UX, graphic design, typography, Figma, inspiration, 3D, architecture)
- "Article" (Blogs, news, essays, deep-dives, op-eds, journalism)
- "Recipe" (Cooking, baking, drinks, food, meal prep, restaurants)
- "Video" (YouTube, TikTok, Reels, documentaries, tutorials in video format)
- "Product" (Shopping, gear, gadgets, books, fashion, hardware to buy)
- "Tool" (SaaS, productivity web apps, utilities, extensions, online calculators)
- "Workout" (Fitness, gym routines, health, exercises, nutrition, yoga)
- "Place" (Travel destinations, cafes, hotels, city guides, maps, locations)
- "Finance" (Investing, crypto, budgeting, business, real estate, stocks)
- "Post" (Social discussions, tweets/threads, Reddit, community discussions)
- "Inspiration" (Ideas, quotes, portfolios, aesthetic collections)
- "Link" (General reference or unclassified)

3. CONCISE AI SUMMARY:
- 1 concise, high-signal sentence (under 100 characters) explaining exactly what the user will find when they open this link.

4. TARGETED TAGS:
- 3 to 5 lowercase keyword tags (e.g., ["flutter", "dart", "mobile-dev"]).

Return ONLY a valid raw JSON object (strictly no markdown formatting, no code blocks):
{
  "title": "Short Punchy Title (2-4 words)",
  "summary": "1 concise high-signal summary sentence.",
  "category": "Selected Category",
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
        } elseif (str_contains($url, 'recipe') || str_contains($title, 'recipe') || str_contains($title, 'cook') || str_contains($title, 'food')) {
            $category = 'Recipe';
        } elseif (str_contains($host, 'github') || str_contains($host, 'gitlab') || str_contains($host, 'stackoverflow') || str_contains($url, 'flutter') || str_contains($url, 'react') || str_contains($url, 'laravel')) {
            $category = 'Tech';
        } elseif (str_contains($host, 'figma') || str_contains($host, 'dribbble') || str_contains($host, 'behance')) {
            $category = 'Design';
        } elseif (str_contains($host, 'amazon') || str_contains($host, 'aliexpress') || str_contains($url, 'shop') || str_contains($url, 'product')) {
            $category = 'Product';
        } elseif (str_contains($host, 'instagram') || str_contains($host, 'twitter') || str_contains($host, 'x.com') || str_contains($host, 'reddit')) {
            $category = 'Post';
        }

        return [
            'title' => $this->condenseTitle($title, $url),
            'summary' => "Saved link from {$host}: {$title}",
            'category' => $category,
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
