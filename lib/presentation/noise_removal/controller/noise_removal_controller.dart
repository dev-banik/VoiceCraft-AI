import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';

class NoiseRemovalState {
  final double strength;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const NoiseRemovalState({
    this.strength = 0.6,
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  NoiseRemovalState copyWith({
    double? strength,
    bool? isProcessing,
    String? resultPath,
    String? error,
  }) {
    return NoiseRemovalState(
      strength: strength ?? this.strength,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: resultPath ?? this.resultPath,
      error: error,
    );
  }
}

class NoiseRemovalController extends StateNotifier<NoiseRemovalState> {
  final Ref ref;
  final String recordingId;

  NoiseRemovalController(this.ref, this.recordingId)
      : super(const NoiseRemovalState());

  void setStrength(double value) => state = state.copyWith(strength: value);

  Future<void> process(String sourcePath) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final output = await ref
          .read(noiseRemovalServiceProvider)
          .removeNoise(sourcePath, strength: state.strength);
      state = state.copyWith(isProcessing: false, resultPath: output);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<void> save(RecordingEntity recording) async {
    if (state.resultPath == null) return;
    final updated = recording.copyWith(denoisedPath: state.resultPath);
    await ref.read(recordingUsecasesProvider).save(updated);
  }
}

final noiseRemovalControllerProvider = StateNotifierProvider.family<
    NoiseRemovalController, NoiseRemovalState, String>(
  (ref, recordingId) => NoiseRemovalController(ref, recordingId),
);
