import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'storage_location.dart';

/// Filesystem helpers for the recordings directory.
///
/// Layout on disk, under whichever root [StorageLocation.recordingsRoot]
/// resolves to — the public "VoiceCraft AI" folder when the user has granted
/// access to it, app-private storage otherwise:
///   <root>/recordings/<id>.<ext>            original take
///   <root>/recordings/<id>_denoised.<ext>    noise-removal output
///   <root>/recordings/<id>_<theme>.<ext>     voice-theme output
///   <root>/recordings/<id>_edit_<n>.<ext>     editor exports
const Uuid _uuid = Uuid();

class FileUtils {
  FileUtils._();

  static Future<Directory> recordingsDirectory() =>
      StorageLocation.recordingsRoot();

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
