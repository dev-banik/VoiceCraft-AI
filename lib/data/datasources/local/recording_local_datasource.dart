import '../../../core/error/exceptions.dart';
import '../../models/recording_model.dart';
import 'hive_boxes.dart';
import 'library_manifest.dart';

/// Direct Hive access for recordings. Throws [LocalStorageException] on
/// failure; the repository translates these into [Failure]s.
class RecordingLocalDatasource {
  const RecordingLocalDatasource();

  Stream<List<RecordingModel>> watchAll() async* {
    yield HiveBoxes.recordings.values.toList();
    yield* HiveBoxes.recordings
        .watch()
        .map((_) => HiveBoxes.recordings.values.toList());
  }

  List<RecordingModel> getAll() => HiveBoxes.recordings.values.toList();

  RecordingModel? getById(String id) {
    try {
      return HiveBoxes.recordings.values
          .firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(RecordingModel model) async {
    try {
      await HiveBoxes.recordings.put(model.id, model);
    } catch (e) {
      throw LocalStorageException('Failed to save recording: $e');
    }
    await _mirrorToManifest();
  }

  Future<void> delete(String id) async {
    try {
      await HiveBoxes.recordings.delete(id);
    } catch (e) {
      throw LocalStorageException('Failed to delete recording: $e');
    }
    await _mirrorToManifest();
  }

  /// Rewrites the shared-storage manifest after every change, so the copy
  /// that survives an uninstall is never behind the database. It writes
  /// nothing at all when shared storage isn't available, and never throws —
  /// a manifest problem must not fail the save the user actually asked for.
  Future<void> _mirrorToManifest() =>
      LibraryManifest.write(HiveBoxes.recordings.values.toList());
}
