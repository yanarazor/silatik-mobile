import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class CacheUtils {
  static Future<int> clear() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    var freed = 0;
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        try {
          freed += await _sizeOf(entity);
          await entity.delete(recursive: true);
        } catch (_) {
          // A locked or already-removed entry must not stop the cleanup.
        }
      }
    } catch (_) {
      // No temp dir available (unsupported platform) — nothing to clear.
    }
    return freed;
  }

  static Future<int> _sizeOf(FileSystemEntity entity) async {
    if (entity is File) {
      return entity.existsSync() ? entity.lengthSync() : 0;
    }
    if (entity is Directory) {
      var total = 0;
      await for (final child in entity.list(recursive: true)) {
        if (child is File && child.existsSync()) total += child.lengthSync();
      }
      return total;
    }
    return 0;
  }
}
