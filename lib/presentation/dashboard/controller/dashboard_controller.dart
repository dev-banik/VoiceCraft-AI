import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';

final StreamProvider<List<RecordingEntity>> recordingsStreamProvider =
    StreamProvider<List<RecordingEntity>>((ref) {
  return ref.watch(recordingUsecasesProvider).watchAll();
});

/// Which shelf of the library the landing screen is showing.
enum LibraryTab { all, videos, modified, originals }

extension LibraryTabLabel on LibraryTab {
  String get label {
    switch (this) {
      case LibraryTab.all:
        return 'All';
      case LibraryTab.videos:
        return 'Videos';
      case LibraryTab.modified:
        return 'Modified';
      case LibraryTab.originals:
        return 'Originals';
    }
  }

  bool matches(RecordingEntity r) {
    switch (this) {
      case LibraryTab.all:
        return r.isInLibrary;
      case LibraryTab.videos:
        return r.isInLibrary && r.isVideo;
      case LibraryTab.modified:
        return r.isModified;
      case LibraryTab.originals:
        return r.isArchivedOriginal;
    }
  }
}

class LibraryFilters {
  final LibraryTab tab;
  final bool denoisedOnly;
  final bool themeAppliedOnly;

  const LibraryFilters({
    this.tab = LibraryTab.all,
    this.denoisedOnly = false,
    this.themeAppliedOnly = false,
  });

  bool get hasChipFilter => denoisedOnly || themeAppliedOnly;

  LibraryFilters copyWith({
    LibraryTab? tab,
    bool? denoisedOnly,
    bool? themeAppliedOnly,
  }) {
    return LibraryFilters(
      tab: tab ?? this.tab,
      denoisedOnly: denoisedOnly ?? this.denoisedOnly,
      themeAppliedOnly: themeAppliedOnly ?? this.themeAppliedOnly,
    );
  }

  bool allows(RecordingEntity r) {
    if (!tab.matches(r)) return false;
    if (denoisedOnly && !r.hasNoiseRemoval) return false;
    if (themeAppliedOnly && !r.hasThemeApplied) return false;
    return true;
  }
}

final StateProvider<LibraryFilters> libraryFiltersProvider =
    StateProvider<LibraryFilters>((ref) => const LibraryFilters());

/// The recordings the landing list should show, after the tab and the
/// chips have both been applied.
final Provider<List<RecordingEntity>> visibleRecordingsProvider =
    Provider<List<RecordingEntity>>((ref) {
  final all = ref.watch(recordingsStreamProvider).valueOrNull ?? const [];
  final filters = ref.watch(libraryFiltersProvider);
  return all.where(filters.allows).toList();
});

/// How many recordings sit on each tab, for the counts in the tab labels.
final Provider<Map<LibraryTab, int>> libraryTabCountsProvider =
    Provider<Map<LibraryTab, int>>((ref) {
  final all = ref.watch(recordingsStreamProvider).valueOrNull ?? const [];
  return {
    for (final tab in LibraryTab.values)
      tab: all.where(tab.matches).length,
  };
});

final FutureProvider<int> totalStorageBytesProvider =
    FutureProvider<int>((ref) async {
  final recordings = ref.watch(recordingsStreamProvider).valueOrNull ?? [];
  // Counts archived originals too — they occupy real space on the device,
  // and hiding that would make the storage figure misleading.
  return recordings.fold<int>(0, (sum, r) => sum + r.sizeBytes);
});

final Provider<int> totalRecordingsCountProvider = Provider<int>((ref) {
  final all = ref.watch(recordingsStreamProvider).valueOrNull ?? const [];
  return all.where((r) => r.isInLibrary).length;
});

final Provider<List<RecordingEntity>> recentRecordingsProvider =
    Provider<List<RecordingEntity>>((ref) {
  final all = ref.watch(recordingsStreamProvider).valueOrNull ?? [];
  return all.where((r) => r.isInLibrary).take(5).toList();
});
