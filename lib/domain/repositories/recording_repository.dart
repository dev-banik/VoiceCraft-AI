import '../../core/utils/result.dart';
import '../entities/recording_entity.dart';

/// Domain contract for reading/writing recordings. Implemented by
/// [data/repositories/recording_repository_impl.dart], which fans out to the
/// local Hive datasource and (when signed in) the remote Firestore/Storage
/// datasources.
abstract class RecordingRepository {
  Stream<List<RecordingEntity>> watchAll();
  Future<Result<List<RecordingEntity>>> getAll();
  Future<Result<RecordingEntity?>> getById(String id);
  Future<Result<void>> save(RecordingEntity recording);
  Future<Result<void>> delete(String id);
  Future<Result<void>> rename(String id, String newTitle);
  Future<Result<List<RecordingEntity>>> search({
    String? query,
    bool? noiseRemovedOnly,
    bool? themeAppliedOnly,
    bool? syncedOnly,
    bool? localOnly,
  });
  Future<Result<int>> totalStorageBytes();
}
