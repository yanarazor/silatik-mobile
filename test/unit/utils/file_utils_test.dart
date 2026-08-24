import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/file_utils.dart';

void main() {
  group('FileUtils.formatBytes', () {
    test('formats 0 bytes as KB', () {
      expect(FileUtils.formatBytes(0), '0 KB');
    });

    test('formats bytes less than 1 KB', () {
      expect(FileUtils.formatBytes(512), '1 KB');
    });

    test('formats exactly 1 KB', () {
      expect(FileUtils.formatBytes(1024), '1 KB');
    });

    test('formats 512 KB', () {
      expect(FileUtils.formatBytes(512 * 1024), '512 KB');
    });

    test('formats exactly 1 MB', () {
      expect(FileUtils.formatBytes(1024 * 1024), '1.00 MB');
    });

    test('formats 5 MB', () {
      expect(FileUtils.formatBytes(5 * 1024 * 1024), '5.00 MB');
    });

    test('formats 2.5 MB', () {
      expect(FileUtils.formatBytes((2.5 * 1024 * 1024).toInt()), '2.50 MB');
    });

    test('formats values just under 1 MB as KB', () {
      const justUnder1MB = 1024 * 1024 - 1;
      expect(FileUtils.formatBytes(justUnder1MB), '1024 KB');
    });
  });

  group('FileUtils.maxSizeBytes', () {
    test('is 5 MB', () {
      expect(FileUtils.maxSizeBytes, 5 * 1024 * 1024);
    });
  });
}
