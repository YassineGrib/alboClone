<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy — Later</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --canvas: #F7F6F3;
            --surface: #FFFFFF;
            --ink: #2F3437;
            --muted: #787774;
            --line: #E8E6E1;
            --font: "IBM Plex Sans", "IBM Plex Sans Arabic", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --canvas: #141413;
                --surface: #1E1E1C;
                --ink: #EDEDEC;
                --muted: #9B9A97;
                --line: #2E2E2A;
            }
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: var(--canvas);
            color: var(--ink);
            font-family: var(--font);
            line-height: 1.65;
            padding: 40px 20px;
        }
        .container {
            max-width: 760px;
            margin: 0 auto;
        }
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            color: var(--muted);
            text-decoration: none;
            font-size: 14px;
            margin-bottom: 32px;
            font-weight: 500;
        }
        .back-link:hover { color: var(--ink); }
        h1 {
            font-size: 32px;
            font-weight: 700;
            letter-spacing: -0.5px;
            margin-bottom: 8px;
        }
        .updated {
            font-size: 13px;
            color: var(--muted);
            margin-bottom: 32px;
        }
        .section {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 20px;
        }
        h2 {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 12px;
        }
        p, ul {
            font-size: 15px;
            color: var(--ink);
            margin-bottom: 12px;
        }
        ul { padding-left: 20px; }
        li { margin-bottom: 6px; }
        .highlight {
            color: var(--muted);
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
            Back to Later
        </a>
        <h1>Privacy Policy</h1>
        <p class="updated">Last updated: August 19, 2026</p>

        <div class="section">
            <h2>1. Overview & Commitment</h2>
            <p>Later ("we", "our", or "the app") is designed to be a quiet, privacy-conscious bookmarking and link organizing tool. We prioritize data minimization: we only collect the information necessary to provide our core services.</p>
        </div>

        <div class="section">
            <h2>2. Information We Collect</h2>
            <ul>
                <li><strong>Account Information:</strong> When you register, we collect your name, email address, and an encrypted hash of your password. Passwords are never stored in plain text (bcrypt hashing).</li>
                <li><strong>Saved Links & Bookmarks:</strong> URLs and content you choose to save in the app, including automatically generated summaries, tags, categories, and folders.</li>
                <li><strong>Technical & Diagnostics:</strong> Basic network request timestamps and error logs to ensure service reliability.</li>
            </ul>
        </div>

        <div class="section">
            <h2>3. AI Processing & Third-Party Services</h2>
            <p>When AI features are enabled, saved URLs and page titles may be processed through Google Gemini API exclusively for summarization and category extraction. No personal user data or identities are shared with AI models.</p>
        </div>

        <div class="section">
            <h2>4. Data Security & Storage</h2>
            <ul>
                <li>All network communications between the mobile application and our servers are encrypted using modern Transport Layer Security (TLS / HTTPS).</li>
                <li>Auth tokens on your mobile device are stored securely inside the operating system's hardware-backed secure storage (Android Keystore / iOS Keychain).</li>
            </ul>
        </div>

        <div class="section">
            <h2>5. Account & Data Deletion Rights</h2>
            <p>You have full ownership of your data. You can delete your account and all associated bookmarks at any time directly from the mobile app (<strong>Settings &rarr; Delete Account</strong>) or via our <a href="/data-deletion" style="color: inherit; text-decoration: underline;">Data Deletion Request page</a>.</p>
        </div>

        <div class="section">
            <h2>6. Contact Us</h2>
            <p>If you have any questions about this Privacy Policy or your personal data, please contact us at <a href="mailto:privacy@later-dz.site" style="color: inherit; text-decoration: underline;">privacy@later-dz.site</a>.</p>
        </div>
    </div>
</body>
</html>
