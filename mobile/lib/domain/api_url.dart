bool isLaterApiUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  return uri != null &&
      (uri.isScheme('http') || uri.isScheme('https')) &&
      uri.host.isNotEmpty;
}
