import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/api_url.dart';

void main() {
  test('accepts http and https hosts', () {
    expect(isLaterApiUrl('http://127.0.0.1:8080'), isTrue);
    expect(isLaterApiUrl('https://later.example.com'), isTrue);
    expect(isLaterApiUrl('  http://192.168.1.4:8080  '), isTrue);
  });

  test('rejects missing host or scheme', () {
    expect(isLaterApiUrl(''), isFalse);
    expect(isLaterApiUrl('192.168.1.4:8080'), isFalse);
    expect(isLaterApiUrl('ftp://127.0.0.1:8080'), isFalse);
    expect(isLaterApiUrl('http://'), isFalse);
  });
}
