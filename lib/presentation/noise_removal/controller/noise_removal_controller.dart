import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../shared/recording_mutations.dart';

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

  /// Stores the processed file, either over [recording] or as its own entry,
  /// per [mode]. Returns the id of the recording to show afterwards, or null
  /// if nothing was saved.
  Future<String?> save(
    RecordingEntity recording,
    DerivativeSaveMode mode,
  ) async {
    if (state.resultPath == null) return null;
    return saveDerivative(
      ref,
      recordingId: recording.id,
      processedPath: state.resultPath!,
      titleSuffix: 'noise removed',
      mode: mode,
      mark: (r, path) => r.copyWith(denoisedPath: path),
    );
  }
}

final noiseRemovalControllerProvider = StateNotifierProvider.family<
    NoiseRemovalController, NoiseRemovalState, String>(
  (ref, recordingId) => NoiseRemovalController(ref, recordingId),
);
