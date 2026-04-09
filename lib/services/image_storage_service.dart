import 'dart:io';
import 'package:path/path.dart' as p;

/// Copies a picked / captured image into the app-local directory so that
/// history screenshots survive cache clearing by the OS.
class ImageStorageService {
  final String _appDir;

  ImageStorageService(this._appDir);

  /// Copies [sourcePath] into `<appDir>/sachcheck_images/` and returns
  /// the new persistent path. If the copy fails, the original path is returned.
  Future<String> persistImage(String sourcePath) async {
    try {
      final dir = Directory(p.join(_appDir, 'sachcheck_images'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final ext = p.extension(sourcePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = p.join(dir.path, fileName);
      await File(sourcePath).copy(dest);
      return dest;
    } catch (_) {
      // Fallback: return original path
      return sourcePath;
    }
  }
}
