import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Computes local storage usage for the Dashboard's "Storage Usage" stat
/// and the Settings > Storage Management screen.
class StorageUsageService {
  Future<int> recordingsDirectoryBytes() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/recordings');
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
