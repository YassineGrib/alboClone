<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>Later — Save Now, Read Calmly</title>
    <meta name="description" content="A calm, distraction-free space for saved links, articles, and media. Offline-first with SQLite and Gemini AI summary.">

    <!-- Typography: IBM Plex Sans Arabic & Latin -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>

    <style type="text/tailwindcss">
        @theme {
            --font-sans: 'IBM Plex Sans Arabic', 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            --color-canvas: #F7F6F3;
            --color-canvas-dark: #1C1C1A;
            --color-ink: #2F3437;
            --color-ink-dark: #EDEDEC;
            --color-muted: #787774;
            --color-muted-dark: #9B9A97;
            --color-line: #EAEAEA;
            --color-line-dark: #3A3A36;
        }
    </style>

    <style>
        :root {
            --bg-canvas: #F7F6F3;
            --text-ink: #2F3437;
            --text-muted: #787774;
            --border-line: #E5E4DE;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg-canvas: #1C1C1A;
                --text-ink: #EDEDEC;
                --text-muted: #9B9A97;
                --border-line: #3A3A36;
            }
        }

        body {
            background-color: var(--bg-canvas);
            color: var(--text-ink);
            font-family: var(--font-sans);
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        /* Subtle dot grid pattern */
        .grid-canvas {
            background-size: 24px 24px;
            background-image: radial-gradient(circle, rgba(47, 52, 55, 0.06) 1px, transparent 1px);
        }
        @media (prefers-color-scheme: dark) {
            .grid-canvas {
                background-image: radial-gradient(circle, rgba(237, 237, 236, 0.06) 1px, transparent 1px);
            }
        }

        /* Minimalist hairline card without heavy white backgrounds */
        .minimal-box {
            background: transparent;
            border: 1px solid var(--border-line);
        }

        .cta-action {
            transition: transform 0.15s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.15s ease;
        }
        .cta-action:active {
            transform: scale(0.98);
            opacity: 0.92;
        }
    </style>
</head>
<body class="min-h-[100dvh] flex flex-col justify-between grid-canvas selection:bg-[#2F3437] selection:text-white dark:selection:bg-[#EDEDEC] dark:selection:text-[#1C1C1A]">

    <!-- Minimal Header -->
    <header class="w-full max-w-md mx-auto px-6 pt-5 pb-3 flex items-center justify-between">
        <a href="/" class="flex items-center gap-2.5 group">
            <!-- Later Brand Vector Mark -->
            <svg class="h-6 w-auto text-[#2F3437] dark:text-[#EDEDEC]" viewBox="0 0 727 852" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path fill="currentColor" transform="matrix(-1 0 0 1 983 -118)" d="M534.336 152.955C543.446 152.279 552.47 156.218 560.412 160.25C595.082 177.859 627.777 200.924 658.774 224.259C760.928 301.158 910.673 442.644 950.009 563.12C960.386 594.902 964.157 629.845 948.373 660.523C932.741 690.907 905.739 717.054 880.12 739.086C787.696 818.573 656.487 884.281 540.374 921.104C474.786 940.984 379.442 963.403 313.066 934.56C302.32 929.015 281.774 919.861 276.666 908.55C272.37 899.038 295.84 894.086 301.966 893.124C374.569 881.596 451.682 880.832 522.789 861.524C592.77 842.521 655.979 813.068 654.117 730.312C652.835 673.386 641.044 621.908 626.246 567.313C612.343 517.196 597.22 467.425 580.89 418.044C564.985 368.679 548.276 318.683 534.391 268.25L534.079 267.123L534.077 267.116C527.271 242.409 511.266 184.303 522.985 160.754C525.203 156.295 529.562 154.097 534.336 152.955Z"/>
            </svg>
            <span class="font-bold text-lg tracking-tight text-[#2F3437] dark:text-[#EDEDEC]">Later</span>
        </a>

        <!-- Status Dot -->
        <div class="flex items-center gap-1.5 text-xs text-[#787774] dark:text-[#9B9A97] font-mono">
            <span class="w-1.5 h-1.5 rounded-full bg-[#346538] dark:bg-[#76c27c]"></span>
            <span>later-dz.site</span>
        </div>
    </header>

    <!-- Main Content -->
    <main class="w-full max-w-md mx-auto px-6 py-4 flex-1 flex flex-col justify-center">

        <!-- Title Section -->
        <div class="space-y-2 mb-6">
            <h1 class="text-3xl font-bold tracking-tight text-[#2F3437] dark:text-[#EDEDEC] leading-tight">
                Save now.<br/>
                Read calmly later.
            </h1>
            <p class="text-sm text-[#787774] dark:text-[#9B9A97] leading-relaxed">
                A serene pocket for your links, recipes, and videos from Chrome, TikTok, and Instagram.
            </p>
        </div>

        <!-- Minimalist App View Preview (No white card background) -->
        <div class="minimal-box rounded-xl p-4 mb-6 divide-y divide-[#E5E4DE] dark:divide-[#3A3A36]">
            
            <!-- Item 1: Synced Article -->
            <div class="pb-3.5">
                <div class="flex items-center justify-between gap-2 mb-1">
                    <span class="text-xs font-semibold text-[#2F3437] dark:text-[#EDEDEC] truncate">
                        Building Fluid Micro-interactions with Flutter
                    </span>
                    <span class="text-[10px] font-mono text-[#346538] dark:text-[#76c27c]">Synced</span>
                </div>
                <p class="text-xs text-[#787774] dark:text-[#9B9A97] line-clamp-2 leading-relaxed">
                    Gemini AI: A guide on high-performance spring animations and sensory UI feedback.
                </p>
                <div class="flex items-center gap-2 text-[10px] text-[#787774] dark:text-[#9B9A97] mt-2 font-mono">
                    <span>Article</span>
                    <span>•</span>
                    <span>2 min read</span>
                </div>
            </div>

            <!-- Item 2: Saved Video Link -->
            <div class="pt-3.5">
                <div class="flex items-center justify-between gap-2 mb-1">
                    <span class="text-xs font-semibold text-[#2F3437] dark:text-[#EDEDEC] truncate">
                        Minimalist Coffee Pour-Over Technique
                    </span>
                    <span class="text-[10px] font-mono text-[#956400] dark:text-[#e0a82e]">Offline</span>
                </div>
                <p class="text-xs text-[#787774] dark:text-[#9B9A97] font-mono truncate">
                    instagram.com/reels/C8k...
                </p>
            </div>

        </div>

        <!-- Download Button (Solid Ink / High-contrast, no heavy elevation) -->
        <div class="space-y-3 mb-8">
            <a href="/downloads/later-v1.0.0-arm64-v8a.apk" 
               download="later-v1.0.0-arm64-v8a.apk"
               class="cta-action w-full flex items-center justify-center gap-2.5 bg-[#2F3437] dark:bg-[#EDEDEC] text-[#F7F6F3] dark:text-[#1C1C1A] font-semibold text-sm py-3.5 px-5 rounded-lg">
                <!-- Phosphor styled download arrow icon -->
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="7 10 12 15 17 10"></polyline>
                    <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                <span>Download Android APK (ARM64 v8a)</span>
            </a>

            <div class="flex items-center justify-between text-[11px] text-[#787774] dark:text-[#9B9A97] font-mono px-1">
                <span>later-v1.0.0-arm64-v8a.apk</span>
                <span>•</span>
                <span>24.5 MB</span>
                <span>•</span>
                <span>Samsung / ARM64</span>
            </div>
        </div>

        <!-- 4 Minimalist Feature List (Using clean SVG icons, no emojis, no card backgrounds) -->
        <div class="space-y-3.5 border-t border-[#E5E4DE] dark:border-[#3A3A36] pt-5">
            
            <div class="flex items-start gap-3">
                <svg class="w-4 h-4 mt-0.5 text-[#2F3437] dark:text-[#EDEDEC] shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="18" cy="5" r="3"></circle>
                    <circle cx="6" cy="12" r="3"></circle>
                    <circle cx="18" cy="19" r="3"></circle>
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"></line>
                    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49"></line>
                </svg>
                <div>
                    <h2 class="text-xs font-semibold text-[#2F3437] dark:text-[#EDEDEC]">System Share Integration</h2>
                    <p class="text-xs text-[#787774] dark:text-[#9B9A97] leading-relaxed">Save directly from Chrome, TikTok, YouTube with one tap.</p>
                </div>
            </div>

            <div class="flex items-start gap-3">
                <svg class="w-4 h-4 mt-0.5 text-[#2F3437] dark:text-[#EDEDEC] shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                </svg>
                <div>
                    <h2 class="text-xs font-semibold text-[#2F3437] dark:text-[#EDEDEC]">Gemini AI Assistant</h2>
                    <p class="text-xs text-[#787774] dark:text-[#9B9A97] leading-relaxed">Automatic summaries, category extraction, and smart tagging.</p>
                </div>
            </div>

            <div class="flex items-start gap-3">
                <svg class="w-4 h-4 mt-0.5 text-[#2F3437] dark:text-[#EDEDEC] shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <ellipse cx="12" cy="5" rx="9" ry="3"></ellipse>
                    <path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path>
                    <path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path>
                </svg>
                <div>
                    <h2 class="text-xs font-semibold text-[#2F3437] dark:text-[#EDEDEC]">Offline-First SQLite</h2>
                    <p class="text-xs text-[#787774] dark:text-[#9B9A97] leading-relaxed">Local device storage with automatic background synchronization.</p>
                </div>
            </div>

        </div>

    </main>

    <!-- Footer -->
    <footer class="w-full max-w-md mx-auto px-6 py-4 flex flex-col gap-2 text-[11px] text-[#787774] dark:text-[#9B9A97] border-t border-[#E5E4DE] dark:border-[#3A3A36] mt-4 font-mono">
        <div class="flex items-center justify-between">
            <span>Later © 2026</span>
            <div class="flex items-center gap-3">
                <a href="/privacy" class="hover:underline">Privacy</a>
                <a href="/terms" class="hover:underline">Terms</a>
                <a href="/data-deletion" class="hover:underline">Deletion</a>
            </div>
        </div>
    </footer>

</body>
</html>
