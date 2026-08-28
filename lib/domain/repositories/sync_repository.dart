import '../../core/utils/result.dart';

/// Domain contract for cloud backup/sync. `syncAll` performs a full
/// incremental sync (upload local-only recordings, pull remote metadata not
/// yet present locally); `syncOne` is used for on-demand "Backup this
/// recording" actions.
abstract class SyncRepository {
  Future<Result<void>> syncAll(String uid);
  Future<Result<void>> syncOne(String uid, String recordingId);
  Stream<double> get progress;
}
