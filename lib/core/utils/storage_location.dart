import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger.dart';

/// Where the recording library lives on disk.
///
/// App-private storage (`getApplicationDocumentsDirectory`) is wiped when the
/// app is uninstalled or its data is cleared, which made every reinstall cost
/// the user every recording they had. So when the platform allows it the
/// library is kept in a plain public folder instead, which outlives the app
/// entirely — reinstall and the recordings are simply still there.
///
/// Access to that folder is a privilege the user grants, so every call here
/// degrades to app-private storage rather than failing. Nothing in the app
/// should assume the shared folder is available.
class StorageLocation {
  StorageLocation._();

  /// Folder name as it appears to the user in their file manager.
  static const String folderName = 'VoiceCraft AI';

  static Directory? _cachedShared;

  /// True when the app may read and write the shared folder.
  static Future<bool> hasSharedAccess() async {
    if (!Platform.isAndroid) return false;
    return Permission.manageExternalStorage.isGranted;
  }

  /// Sends the user to the system screen where "All files access" is granted.
  /// Returns whether access is held afterwards.
  static Future<bool> requestSharedAccess() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) _cachedShared = null;
    return status.isGranted;
  }

  /// The shared library folder, or null when it isn't usable — permission not
  /// granted, not Android, or the volume can't be resolved.
  static Future<Directory?> sharedRoot() async {
    if (_cachedShared != null) return _cachedShared;
    if (!await hasSharedAccess()) return null;

    try {
      // getExternalStorageDirectory gives the app-scoped path on the shared
      // volume — /storage/emulated/0/Android/data/<pkg>/files — which is
      // itself removed on uninstall. Everything before "/Android/" is the
      // volume root, and that is what survives. Deriving it this way rather
      // than hardcoding /storage/emulated/0 keeps it correct on devices
      // where the primary volume is mounted elsewhere.
      final scoped = await getExternalStorageDirectory();
      if (scoped == null) return null;
      final marker = '${Platform.pathSeparator}Android${Platform.pathSeparator}';
      final index = scoped.path.indexOf(marker);
      if (index <= 0) return null;

      final dir = Directory(
        p.join(scoped.path.substring(0, index), folderName),
      );
      if (!await dir.exists()) await dir.create(recursive: true);
      _cachedShared = dir;
      return dir;
    } catch (e) {
      appLogger.w('Shared storage unavailable, staying app-private: $e');
      return null;
    }
  }

  /// The directory recordings are written to: the shared folder when it is
  /// available, app-private storage otherwise.
  static Future<Directory> recordingsRoot() async {
    final shared = await sharedRoot();
    if (shared != null) {
      final dir = Directory(p.join(shared.path, 'recordings'));
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }

    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'recordings'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// True when [path] sits inside app-private storage and would therefore be
  /// lost on uninstall — used to decide what still needs relocating.
  static Future<bool> isAppPrivate(String path) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      return p.isWithin(base.path, path);
    } catch (_) {
      return false;
    }
  }

  /// Forgets the resolved folder, so the next call re-checks permission.
  static void invalidate() => _cachedShared = null;
}
