<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account & Data Deletion — Later</title>
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
            --danger: #9F2F2D;
            --font: "IBM Plex Sans", "IBM Plex Sans Arabic", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --canvas: #141413;
                --surface: #1E1E1C;
                --ink: #EDEDEC;
                --muted: #9B9A97;
                --line: #2E2E2A;
                --danger: #E05D5A;
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
        .container { max-width: 760px; margin: 0 auto; }
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
        h1 { font-size: 32px; font-weight: 700; letter-spacing: -0.5px; margin-bottom: 8px; }
        .subtitle { font-size: 15px; color: var(--muted); margin-bottom: 32px; }
        .section {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 20px;
        }
        h2 { font-size: 18px; font-weight: 600; margin-bottom: 12px; }
        p, ol { font-size: 15px; color: var(--ink); margin-bottom: 12px; }
        ol { padding-left: 20px; }
        li { margin-bottom: 8px; }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            background: rgba(159, 47, 45, 0.1);
            color: var(--danger);
            margin-bottom: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
            Back to Later
        </a>
        <h1>Account & Data Deletion Request</h1>
        <p class="subtitle">Instructions on how to delete your account and associated personal data.</p>

        <div class="section">
            <span class="badge">Immediate in-app deletion</span>
            <h2>Option 1: Delete Directly From The Mobile App</h2>
            <p>You can instantly delete your account and all data at any time without waiting:</p>
            <ol>
                <li>Open the <strong>Later</strong> app on your device.</li>
                <li>Tap the <strong>Settings</strong> icon in the top bar.</li>
                <li>Navigate to the <strong>General / Session</strong> tab.</li>
                <li>Tap <strong>Delete Account & Data</strong> and confirm.</li>
            </ol>
            <p>Your account, authentication tokens, saved bookmarks, folders, and AI metadata are permanently deleted immediately from the database.</p>
        </div>

        <div class="section">
            <h2>Option 2: Submit a Deletion Request via Email</h2>
            <p>If you have uninstalled the app or cannot access your account, you can request manual deletion:</p>
            <ol>
                <li>Send an email to <a href="mailto:privacy@later-dz.site" style="color: inherit; text-decoration: underline;">privacy@later-dz.site</a> with the subject <code>Account Deletion Request</code>.</li>
                <li>Include the email address associated with your account.</li>
            </ol>
            <p>Our system will verify and purge all associated records within 48 hours and send a confirmation email.</p>
        </div>

        <div class="section">
            <h2>What Data Is Deleted?</h2>
            <p>Upon deletion, the following data is permanently purged:</p>
            <ul>
                <li>User identity (name, email address, password hash)</li>
                <li>All saved URLs, titles, thumbnails, and notes</li>
                <li>All folders, tags, and collections</li>
                <li>All active session tokens and API credentials</li>
            </ul>
        </div>
    </div>
</body>
</html>
