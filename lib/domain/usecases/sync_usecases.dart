import '../../core/utils/result.dart';
import '../repositories/sync_repository.dart';

class SyncUsecases {
  final SyncRepository repository;
  const SyncUsecases(this.repository);

  Future<Result<void>> syncAll(String uid) => repository.syncAll(uid);

  Future<Result<void>> syncOne(String uid, String recordingId) =>
      repository.syncOne(uid, recordingId);

  Stream<double> get progress => repository.progress;
}
