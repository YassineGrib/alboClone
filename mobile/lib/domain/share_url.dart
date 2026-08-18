class ShareUrlExtractor {
  static final _url = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
  static final _trail = RegExp(r'[.,!?;:)]+$');

  static String? first(String raw) {
    final match = _url.firstMatch(raw);
    if (match == null) {
      return null;
    }
    return match.group(0)!.replaceAll(_trail, '');
  }
}
