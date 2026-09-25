import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const int maxFileLines = 350;

// Temporary ratchet: files still awaiting refactor. Each entry is removed as
// the corresponding split lands. Must be empty once the migration is complete.
const Set<String> allowedOversize = {};

void main() {
  test('no lib dart file exceeds $maxFileLines lines', () {
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('.dart')) continue;
      if (allowedOversize.contains(path)) continue;

      final lineCount = entity.readAsLinesSync().length;
      if (lineCount > maxFileLines) {
        violations.add('$path ($lineCount lines)');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Oversize files:\n${violations.join('\n')}',
    );
  });
}