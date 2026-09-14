import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/url_opener.dart';

void main() {
  group('isPdfUrl', () {
    test('plain .pdf and with query/fragment route to viewer', () {
      expect(isPdfUrl('https://x/y/file.pdf'), isTrue);
      expect(isPdfUrl('https://x/y/file.PDF'), isTrue);
      expect(isPdfUrl('https://x/y/file.pdf?token=abc'), isTrue);
      expect(isPdfUrl('https://x/y/file.pdf#page=2'), isTrue);
      expect(isPdfUrl('  https://x/file.pdf  '), isTrue);
    });

    test('non-pdf urls open in web view', () {
      expect(isPdfUrl('https://x/y/doc.png'), isFalse);
      expect(isPdfUrl('https://example.com'), isFalse);
      expect(isPdfUrl('https://x/pdf-report'), isFalse);
    });
  });
}
