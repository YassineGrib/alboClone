import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/share_url.dart';

void main() {
  test('returns a bare https url', () {
    expect(
      ShareUrlExtractor.first('https://example.com/x'),
      'https://example.com/x',
    );
  });

  test('pulls the first url out of caption text', () {
    expect(
      ShareUrlExtractor.first('Check this https://vm.tiktok.com/ZMabc/ wow'),
      'https://vm.tiktok.com/ZMabc/',
    );
  });

  test('strips trailing punctuation', () {
    expect(
      ShareUrlExtractor.first('See https://example.com/x.'),
      'https://example.com/x',
    );
  });

  test('returns null when there is no url', () {
    expect(ShareUrlExtractor.first('just a thought'), isNull);
    expect(ShareUrlExtractor.first(''), isNull);
  });
}
