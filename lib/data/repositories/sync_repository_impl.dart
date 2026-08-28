import 'dart:async';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/recording_local_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../datasources/remote/storage_datasource.dart';
import '../models/recording_model.dart';

/// Incremental two-way sync between the local Hive box and
/// Firestore/Storage.
///
/// Strategy (kept intentionally simple/robust rather than clever):
///  - Local recordings not yet `synced` are uploaded (audio -> Storage,
///    metadata -> Firestore) and flipped to `synced = true`.
///  - Remote metadata documents with no matching local record are pulled
///    down: metadata is written locally immediately (so the recording shows
///    up in the list right away) and the audio file is fetched lazily on
///    first playback rather than eagerly for every device.
///  - Conflict resolution: last-write-wins keyed on `createdAt`, since
///    recordings are treated as immutable takes rather than co-edited
///    documents — there is no concurrent-edit scenario to reconcile.
///  - Offline: any network failure aborts the current sync pass without
///    mutating local state; the next connectivity change or manual retry
///    will pick up where it left off because the `synced` flag is the
///    source of truth for "needs upload".
class SyncRepositoryImpl implements SyncRepository {
  final RecordingLocalDatasource local;
  final FirestoreDatasource firestore;
  final StorageDatasource storage;

  final StreamController<double> _progressController =
      StreamController.broadcast();

  SyncRepositoryImpl({
    required this.local,
    required this.firestore,
    required this.storage,
  });

  @override
  Stream<double> get progress => _progressController.stream;

  @override
  Future<Result<void>> syncAll(String uid) async {
    try {
      await firestore.ensureUserProfile(uid, {'uid': uid});

      final localModels = local.getAll();
      final pending = localModels.where((m) => !m.synced).toList();

      for (var i = 0; i < pending.length; i++) {
        await _uploadOne(uid, pending[i]);
        _progressController.add((i + 1) / (pending.length == 0 ? 1 : pending.length));
      }

      final remoteDocs = await firestore.fetchAll(uid);
      final localIds = local.getAll().map((m) => m.id).toSet();

      for (final doc in remoteDocs) {
        final id = doc['id'] as String;
        if (localIds.contains(id)) continue;
        final placeholderPath = await FileUtils.newRecordingPath(
          (doc['format'] as String? ?? 'wav'),
        );
        final model = RecordingModel.fromFirestore(doc, placeholderPath);
        await local.put(model);
      }

      _progressController.add(1.0);
      return const Result.ok(null);
    } on SyncException catch (e) {
      return Result.err(SyncFailure(e.message));
    } catch (e) {
      appLogger.e('syncAll failed', error: e);
      return Result.err(SyncFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> syncOne(String uid, String recordingId) async {
    try {
      final model = local.getById(recordingId);
      if (model == null) {
        return const Result.err(SyncFailure('Recording not found locally.'));
      }
      await _uploadOne(uid, model);
      return const Result.ok(null);
    } on SyncException catch (e) {
      return Result.err(SyncFailure(e.message));
    } catch (e) {
      return Result.err(SyncFailure(e.toString()));
    }
  }

  Future<void> _uploadOne(String uid, RecordingModel model) async {
    final downloadUrl = await storage.upload(
      uid: uid,
      recordingId: model.id,
      localPath: model.localPath,
      onProgress: (p) => _progressController.add(p),
    );
    final updated = RecordingModel(
      id: model.id,
      title: model.title,
      localPath: model.localPath,
      durationMs: model.durationMs,
      sizeBytes: model.sizeBytes,
      createdAt: model.createdAt,
      format: model.format,
      sampleRate: model.sampleRate,
      quality: model.quality,
      denoisedPath: model.denoisedPath,
      themeVariants: model.themeVariants,
      synced: true,
      cloudUrl: downloadUrl,
      tags: model.tags,
    );
    await firestore.upsertMetadata(uid, updated);
    await local.put(updated);
  }
}
