import '../../core/utils/result.dart';
import '../entities/recording_entity.dart';
import '../repositories/recording_repository.dart';

class SearchRecordingsUsecase {
  final RecordingRepository repository;
  const SearchRecordingsUsecase(this.repository);

  Future<Result<List<RecordingEntity>>> call({
    String? query,
    bool? noiseRemovedOnly,
    bool? themeAppliedOnly,
    bool? syncedOnly,
    bool? localOnly,
  }) {
    return repository.search(
      query: query,
      noiseRemovedOnly: noiseRemovedOnly,
      themeAppliedOnly: themeAppliedOnly,
      syncedOnly: syncedOnly,
      localOnly: localOnly,
    );
  }
}
