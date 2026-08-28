import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';

final StreamProvider<List<RecordingEntity>> recordingsStreamProvider =
    StreamProvider<List<RecordingEntity>>((ref) {
  return ref.watch(recordingUsecasesProvider).watchAll();
});

final FutureProvider<int> totalStorageBytesProvider =
    FutureProvider<int>((ref) async {
  final recordings = ref.watch(recordingsStreamProvider).valueOrNull ?? [];
  return recordings.fold<int>(0, (sum, r) => sum + r.sizeBytes);
});

final Provider<int> totalRecordingsCountProvider = Provider<int>((ref) {
  return ref.watch(recordingsStreamProvider).valueOrNull?.length ?? 0;
});

final Provider<List<RecordingEntity>> recentRecordingsProvider =
    Provider<List<RecordingEntity>>((ref) {
  final all = ref.watch(recordingsStreamProvider).valueOrNull ?? [];
  return all.take(5).toList();
});
