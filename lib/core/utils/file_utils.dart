import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Filesystem helpers for the app's private recordings directory.
///
/// Layout on disk:
///   <app documents>/recordings/<id>.<ext>            original take
///   <app documents>/recordings/<id>_denoised.<ext>    noise-removal output
///   <app documents>/recordings/<id>_<theme>.<ext>     voice-theme output
///   <app documents>/recordings/<id>_edit_<n>.<ext>     editor exports
const Uuid _uuid = Uuid();

class FileUtils {
  FileUtils._();

  static Future<Directory> recordingsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'recordings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> newRecordingPath(String extension) async {
    final dir = await recordingsDirectory();
    final id = _uuid.v4();
    return p.join(dir.path, '$id.$extension');
  }

  static Future<String> derivedPath(String sourcePath, String suffix) async {
    final dir = await recordingsDirectory();
    final base = p.basenameWithoutExtension(sourcePath);
    final ext = p.extension(sourcePath);
    return p.join(dir.path, '${base}_$suffix$ext');
  }

  static Future<int> sizeOf(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }

  static Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String newId() => _uuid.v4();
}
