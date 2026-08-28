import '../../core/utils/result.dart';
import '../entities/recording_entity.dart';
import '../repositories/recording_repository.dart';

/// Usecases around CRUD on recordings. Grouped in one file (rather than one
/// class per usecase) to avoid ceremony for what are thin repository calls;
/// split out if any of these grow real business logic.
class RecordingUsecases {
  final RecordingRepository repository;
  const RecordingUsecases(this.repository);

  Stream<List<RecordingEntity>> watchAll() => repository.watchAll();

  Future<Result<void>> save(RecordingEntity recording) =>
      repository.save(recording);

  Future<Result<void>> delete(String id) => repository.delete(id);

  Future<Result<void>> rename(String id, String newTitle) =>
      repository.rename(id, newTitle);

  Future<Result<RecordingEntity?>> getById(String id) =>
      repository.getById(id);

  Future<Result<int>> totalStorageBytes() => repository.totalStorageBytes();
}
