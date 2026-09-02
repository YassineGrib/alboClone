<?php

namespace Tests\Unit;

use App\Services\LinkPreview;
use PHPUnit\Framework\TestCase;

class LinkPreviewTest extends TestCase
{
    public function test_reads_open_graph_title_and_image(): void
    {
        $html = <<<'HTML'
        <html><head>
          <meta property="og:title" content="Grilled peaches">
          <meta property="og:image" content="https://cdn.example.com/peach.jpg">
        </head></html>
        HTML;

        $preview = LinkPreview::fromHtml($html, 'https://example.com/recipe');

        $this->assertSame('Grilled peaches', $preview->title);
        $this->assertSame('https://cdn.example.com/peach.jpg', $preview->imageUrl);
    }

    public function test_falls_back_to_title_tag(): void
    {
        $html = '<html><head><title>  Plain title  </title></head></html>';
        $preview = LinkPreview::fromHtml($html, 'https://example.com/x');

        $this->assertSame('Plain title', $preview->title);
        $this->assertSame('https://www.google.com/s2/favicons?domain=example.com&sz=128', $preview->imageUrl);
    }

    public function test_resolves_relative_image_urls(): void
    {
        $html = '<html><head><meta property="og:image" content="/img/a.jpg"></head></html>';
        $preview = LinkPreview::fromHtml($html, 'https://example.com/page');

        $this->assertSame('https://example.com/img/a.jpg', $preview->imageUrl);
    }

    public function test_reads_description_meta_tags(): void
    {
        $html = <<<'HTML'
        <html><head>
          <meta property="og:title" content="Classic Tiramisu">
          <meta property="og:description" content="Authentic Italian recipe with mascarpone and espresso.">
          <meta property="og:image" content="https://cdn.example.com/tiramisu.jpg">
        </head></html>
        HTML;

        $preview = LinkPreview::fromHtml($html, 'https://example.com/tiramisu');

        $this->assertSame('Classic Tiramisu', $preview->title);
        $this->assertSame('Authentic Italian recipe with mascarpone and espresso.', $preview->description);
    }
}

