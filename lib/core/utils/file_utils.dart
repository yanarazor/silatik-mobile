import 'package:file_picker/file_picker.dart';

class FileUtils {
  static const maxSizeBytes = 5 * 1024 * 1024;

  static String formatBytes(int bytes) {
    final kb = bytes / 1024;
    final mb = kb / 1024;
    if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
    return '${kb.toStringAsFixed(0)} KB';
  }

  static bool isAllowed(PlatformFile file, {required List<String> exts}) {
    final ext = file.extension?.toLowerCase();
    if (ext == null) return false;
    return exts.contains(ext);
  }
}
