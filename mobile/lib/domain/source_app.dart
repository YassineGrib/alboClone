class SourceApp {
  static String idFor(String url) {
    final host = (Uri.tryParse(url)?.host ?? '').toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host.endsWith('tiktok.com')) {
      return 'tiktok';
    }
    if (host.endsWith('instagram.com') || host == 'instagr.am') {
      return 'instagram';
    }
    if (host.endsWith('youtube.com') || host == 'youtu.be') {
      return 'youtube';
    }
    if (host.endsWith('vimeo.com')) {
      return 'vimeo';
    }
    if (host == 'x.com' || host.endsWith('twitter.com')) {
      return 'x';
    }
    if (host.endsWith('reddit.com')) {
      return 'reddit';
    }
    if (host.isEmpty) {
      return 'web';
    }
    return host;
  }

  static String label(String id) {
    return switch (id) {
      'tiktok' => 'TikTok',
      'instagram' => 'Instagram',
      'youtube' => 'YouTube',
      'vimeo' => 'Vimeo',
      'x' => 'X',
      'reddit' => 'Reddit',
      'web' => 'Web',
      _ => id,
    };
  }
}
