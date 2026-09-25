import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/utils/logger.dart';
import '../../../core/utils/storage_location.dart';
import '../../models/recording_model.dart';

/// A plain-JSON index of the library, written beside the audio in shared
/// storage.
///
/// The Hive database lives in app-private storage and dies with the app, so
/// on a reinstall the audio files would still be sitting in the public folder
/// with nothing left that knew their titles, durations or which take was
/// derived from which. This manifest is that knowledge, kept somewhere that
/// survives, and is what [restoreIfEmpty] rebuilds the database from.
///
/// It is written on every change rather than on a schedule: the library is a
/// handful of small records, and a manifest that can lag behind is a manifest
/// that restores the wrong thing.
class LibraryManifest {
  LibraryManifest._();

  static const String fileName = 'library.json';

  static Future<File?> _file() async {
    final root = await StorageLocation.sharedRoot();
    if (root == null) return null;
    return File(p.join(root.path, fileName));
  }

  /// Writes [models] out. Failures are logged and swallowed — losing the
  /// manifest degrades recovery, but must never break saving a recording.
  static Future<void> write(List<RecordingModel> models) async {
    try {
      final file = await _file();
      if (file == null) return;
      final payload = {
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'recordings': models.map((m) => m.toJson()).toList(),
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    } catch (e) {
      appLogger.w('Could not write library manifest: $e');
    }
  }

  /// Reads the manifest, dropping any entry whose audio is no longer on disk
  /// so a restore can't repopulate the library with dead rows.
  static Future<List<RecordingModel>> read() async {
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return const [];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final rows = decoded['recordings'];
      if (rows is! List) return const [];

      final models = <RecordingModel>[];
      for (final row in rows) {
        if (row is! Map) continue;
        try {
          final model = RecordingModel.fromJson(row.cast<String, dynamic>());
          if (await File(model.localPath).exists()) models.add(model);
        } catch (e) {
          appLogger.w('Skipping unreadable manifest entry: $e');
        }
      }
      return models;
    } catch (e) {
      appLogger.w('Could not read library manifest: $e');
      return const [];
    }
  }
}
