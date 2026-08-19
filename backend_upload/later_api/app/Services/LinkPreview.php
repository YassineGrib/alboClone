<?php

namespace App\Services;

class LinkPreview
{
    public function __construct(
        public readonly ?string $title,
        public readonly ?string $imageUrl,
    ) {}

    public static function fromHtml(string $html, string $pageUrl): self
    {
        $title = self::meta($html, 'og:title')
            ?? self::meta($html, 'twitter:title')
            ?? self::titleTag($html);

        $image = self::meta($html, 'og:image')
            ?? self::meta($html, 'twitter:image')
            ?? self::linkRel($html, 'apple-touch-icon')
            ?? self::linkRel($html, 'icon')
            ?? self::linkRel($html, 'shortcut icon');

        if ($image === null || trim($image) === '') {
            $host = strtolower(parse_url($pageUrl, PHP_URL_HOST) ?? '');
            if (!empty($host)) {
                $image = "https://www.google.com/s2/favicons?domain={$host}&sz=128";
            }
        }

        return new self(
            title: $title !== null ? html_entity_decode(trim($title), ENT_QUOTES | ENT_HTML5, 'UTF-8') : null,
            imageUrl: self::absolutize($image, $pageUrl),
        );
    }

    public static function fromOEmbed(array $payload): self
    {
        $title = isset($payload['title']) ? trim((string) $payload['title']) : null;
        $image = isset($payload['thumbnail_url']) ? trim((string) $payload['thumbnail_url']) : null;

        return new self(
            title: $title !== '' ? $title : null,
            imageUrl: $image !== '' ? $image : null,
        );
    }

    private static function meta(string $html, string $property): ?string
    {
        $quoted = preg_quote($property, '/');
        $patterns = [
            '/<meta[^>]+property=["\']'.$quoted.'["\'][^>]+content=["\']([^"\']+)["\']/i',
            '/<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']'.$quoted.'["\']/i',
            '/<meta[^>]+name=["\']'.$quoted.'["\'][^>]+content=["\']([^"\']+)["\']/i',
            '/<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']'.$quoted.'["\']/i',
        ];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $html, $matches) === 1) {
                return html_entity_decode($matches[1], ENT_QUOTES | ENT_HTML5, 'UTF-8');
            }
        }

        return null;
    }

    private static function linkRel(string $html, string $rel): ?string
    {
        $quoted = preg_quote($rel, '/');
        $pattern = '/<link[^>]+rel=["\'][^"\']*'.$quoted.'[^"\']*["\'][^>]+href=["\']([^"\']+)["\']/i';
        if (preg_match($pattern, $html, $matches) === 1) {
            return html_entity_decode($matches[1], ENT_QUOTES | ENT_HTML5, 'UTF-8');
        }
        return null;
    }

    private static function titleTag(string $html): ?string
    {
        if (preg_match('/<title[^>]*>(.*?)<\/title>/is', $html, $matches) !== 1) {
            return null;
        }

        $title = trim(html_entity_decode(strip_tags($matches[1]), ENT_QUOTES | ENT_HTML5, 'UTF-8'));

        return $title !== '' ? $title : null;
    }

    private static function absolutize(?string $image, string $pageUrl): ?string
    {
        if ($image === null || trim($image) === '') {
            return null;
        }

        $image = trim($image);
        if (str_starts_with($image, 'http://') || str_starts_with($image, 'https://')) {
            return $image;
        }

        $parts = parse_url($pageUrl);
        if ($parts === false || ! isset($parts['scheme'], $parts['host'])) {
            return null;
        }

        $origin = $parts['scheme'].'://'.$parts['host'];
        if (isset($parts['port'])) {
            $origin .= ':'.$parts['port'];
        }

        if (str_starts_with($image, '//')) {
            return $parts['scheme'].':'.$image;
        }

        if (str_starts_with($image, '/')) {
            return $origin.$image;
        }

        $path = $parts['path'] ?? '/';
        $dir = str_contains($path, '.') ? dirname($path) : rtrim($path, '/');

        return $origin.'/'.ltrim($dir.'/'.$image, '/');
    }
}
