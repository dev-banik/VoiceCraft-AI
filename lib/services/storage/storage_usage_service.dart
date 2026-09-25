import 'dart:io';

import '../../core/utils/file_utils.dart';

/// Computes local storage usage for the Dashboard's "Storage Usage" stat
/// and the Settings > Storage Management screen.
class StorageUsageService {
  Future<int> recordingsDirectoryBytes() async {
    // Asks FileUtils where recordings actually live rather than assuming
    // app-private storage. Once the library moved to the public folder this
    // was measuring an empty directory and reporting 0 B.
    final dir = await FileUtils.recordingsDirectory();
    if (!await dir.exists()) return 0;

    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<int?> deviceFreeSpaceBytes() async {
    // Free-space querying is platform-specific and not exposed uniformly by
    // path_provider; left as a documented extension point rather than
    // pulling in an extra plugin for one stat. Returns null when unknown so
    // the UI can hide the "free space" line instead of showing a fake 0.
    return null;
  }
}
