import '../../../core/error/exceptions.dart';
import '../../models/recording_model.dart';
import 'hive_boxes.dart';

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
  }

  Future<void> delete(String id) async {
    try {
      await HiveBoxes.recordings.delete(id);
    } catch (e) {
      throw LocalStorageException('Failed to delete recording: $e');
    }
  }
}
