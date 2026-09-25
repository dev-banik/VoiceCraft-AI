import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/utils/logger.dart';
import '../../../core/utils/storage_location.dart';
import '../../models/recording_model.dart';
import 'hive_boxes.dart';
import 'library_manifest.dart';

/// Keeps the library and the audio in shared storage in step at startup.
///
/// Two directions, and both can matter on the same launch:
///
///  * [migrateToSharedStorage] moves audio that is still sitting in
///    app-private storage out into the public folder, so it stops being
///    hostage to the app staying installed.
///  * [restoreFromManifest] does the reverse for a fresh install: the audio
///    and manifest outlived the uninstall, the database did not, so the
///    database is rebuilt from them.
class LibraryRecovery {
  LibraryRecovery._();

  /// Relocates every file a recording points at into the shared folder,
  /// rewriting the stored paths. No-op when shared storage isn't available,
  /// so a user who declines the permission simply keeps working as before.
  static Future<void> migrateToSharedStorage() async {
    final root = await StorageLocation.sharedRoot();
    if (root == null) return;

    final target = await StorageLocation.recordingsRoot();
    var moved = 0;

    for (final model in HiveBoxes.recordings.values.toList()) {
      try {
        final localPath = await _relocate(model.localPath, target);
        final denoised = await _relocate(model.denoisedPath, target);
        final enhanced = await _relocate(model.enhancedPath, target);

        final variants = <String, String>{};
        for (final entry in model.themeVariants.entries) {
          variants[entry.key] =
              await _relocate(entry.value, target) ?? entry.value;
        }

        final unchanged = localPath == null &&
            denoised == null &&
            enhanced == null &&
            _sameMap(variants, model.themeVariants);
        if (unchanged) continue;

        await HiveBoxes.recordings.put(
          model.id,
          RecordingModel(
            id: model.id,
            title: model.title,
            localPath: localPath ?? model.localPath,
            durationMs: model.durationMs,
            sizeBytes: model.sizeBytes,
            createdAt: model.createdAt,
            format: model.format,
            sampleRate: model.sampleRate,
            quality: model.quality,
            denoisedPath: denoised ?? model.denoisedPath,
            enhancedPath: enhanced ?? model.enhancedPath,
            themeVariants: variants,
            kind: model.kind,
            sourceRecordingId: model.sourceRecordingId,
            synced: model.synced,
            cloudUrl: model.cloudUrl,
            tags: model.tags,
          ),
        );
        moved++;
      } catch (e) {
        // One bad file must not stop the rest from being made safe.
        appLogger.w('Could not migrate recording ${model.id}: $e');
      }
    }

    if (moved > 0) {
      appLogger.i('Moved $moved recording(s) into shared storage.');
    }
    await LibraryManifest.write(HiveBoxes.recordings.values.toList());
  }

  /// Rebuilds an empty database from the manifest left in shared storage.
  ///
  /// Guarded on the box being empty: this should only ever fire on a fresh
  /// install, never overwrite a library the user already has.
  static Future<int> restoreFromManifest() async {
    if (HiveBoxes.recordings.isNotEmpty) return 0;

    final models = await LibraryManifest.read();
    if (models.isEmpty) return 0;

    for (final model in models) {
      await HiveBoxes.recordings.put(model.id, model);
    }
    appLogger.i('Restored ${models.length} recording(s) from shared storage.');
    return models.length;
  }

  /// Copies [path] into [target] when it is still in app-private storage.
  /// Returns the new path, or null when nothing needed doing.
  static Future<String?> _relocate(String? path, Directory target) async {
    if (path == null) return null;
    if (!await StorageLocation.isAppPrivate(path)) return null;

    final source = File(path);
    if (!await source.exists()) return null;

    final destination = File(p.join(target.path, p.basename(path)));
    if (await destination.exists()) return destination.path;

    await source.copy(destination.path);
    // Copy first, delete after: an interrupted move must never be the case
    // that loses the only copy.
    try {
      await source.delete();
    } catch (e) {
      appLogger.w('Copied but could not remove $path: $e');
    }
    return destination.path;
  }

  static bool _sameMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
