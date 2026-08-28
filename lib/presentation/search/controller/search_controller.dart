import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';

class SearchFilters {
  final String query;
  final bool noiseRemovedOnly;
  final bool themeAppliedOnly;
  final bool syncedOnly;
  final bool localOnly;

  const SearchFilters({
    this.query = '',
    this.noiseRemovedOnly = false,
    this.themeAppliedOnly = false,
    this.syncedOnly = false,
    this.localOnly = false,
  });

  SearchFilters copyWith({
    String? query,
    bool? noiseRemovedOnly,
    bool? themeAppliedOnly,
    bool? syncedOnly,
    bool? localOnly,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      noiseRemovedOnly: noiseRemovedOnly ?? this.noiseRemovedOnly,
      themeAppliedOnly: themeAppliedOnly ?? this.themeAppliedOnly,
      syncedOnly: syncedOnly ?? this.syncedOnly,
      localOnly: localOnly ?? this.localOnly,
    );
  }
}

final StateProvider<SearchFilters> searchFiltersProvider =
    StateProvider<SearchFilters>((ref) => const SearchFilters());

final FutureProvider<List<RecordingEntity>> searchResultsProvider =
    FutureProvider<List<RecordingEntity>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final result = await ref.read(searchRecordingsUsecaseProvider).call(
        query: filters.query,
        noiseRemovedOnly: filters.noiseRemovedOnly ? true : null,
        themeAppliedOnly: filters.themeAppliedOnly ? true : null,
        syncedOnly: filters.syncedOnly ? true : null,
        localOnly: filters.localOnly ? true : null,
      );
  return result.valueOrNull ?? [];
});
