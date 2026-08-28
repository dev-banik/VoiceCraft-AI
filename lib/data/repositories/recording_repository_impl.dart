import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/recording_entity.dart';
import '../../domain/repositories/recording_repository.dart';
import '../datasources/local/recording_local_datasource.dart';
import '../models/recording_model.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  final RecordingLocalDatasource local;

  const RecordingRepositoryImpl(this.local);

  @override
  Stream<List<RecordingEntity>> watchAll() {
    return local.watchAll().map(
          (models) => models.map((m) => m.toEntity()).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Future<Result<List<RecordingEntity>>> getAll() async {
    try {
      final entities = local.getAll().map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result.ok(entities);
    } catch (e) {
      return Result.err(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<RecordingEntity?>> getById(String id) async {
    try {
      return Result.ok(local.getById(id)?.toEntity());
    } catch (e) {
      return Result.err(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> save(RecordingEntity recording) async {
    try {
      await local.put(RecordingModel.fromEntity(recording));
      return const Result.ok(null);
    } on LocalStorageException catch (e) {
      return Result.err(LocalStorageFailure(e.message));
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await local.delete(id);
      return const Result.ok(null);
    } on LocalStorageException catch (e) {
      return Result.err(LocalStorageFailure(e.message));
    } catch (e) {
      return Result.err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> rename(String id, String newTitle) async {
    final model = local.getById(id);
    if (model == null) {
      return const Result.err(LocalStorageFailure('Recording not found.'));
    }
    final updated = RecordingModel.fromEntity(
      model.toEntity().copyWith(title: newTitle),
    );
    return save(updated.toEntity());
  }

  @override
  Future<Result<List<RecordingEntity>>> search({
    String? query,
    bool? noiseRemovedOnly,
    bool? themeAppliedOnly,
    bool? syncedOnly,
    bool? localOnly,
  }) async {
    try {
      var results = local.getAll().map((m) => m.toEntity()).toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        results = results
            .where((r) => r.title.toLowerCase().contains(q))
            .toList();
      }
      if (noiseRemovedOnly == true) {
        results = results.where((r) => r.hasNoiseRemoval).toList();
      }
      if (themeAppliedOnly == true) {
        results = results.where((r) => r.hasThemeApplied).toList();
      }
      if (syncedOnly == true) {
        results = results.where((r) => r.synced).toList();
      }
      if (localOnly == true) {
        results = results.where((r) => r.isLocalOnly).toList();
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result.ok(results);
    } catch (e) {
      return Result.err(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> totalStorageBytes() async {
    try {
      final total = local
          .getAll()
          .fold<int>(0, (sum, m) => sum + m.sizeBytes);
      return Result.ok(total);
    } catch (e) {
      return Result.err(LocalStorageFailure(e.toString()));
    }
  }
}
