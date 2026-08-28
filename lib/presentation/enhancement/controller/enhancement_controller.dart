import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/enhancement_settings.dart';
import '../../../domain/entities/recording_entity.dart';

class EnhancementState {
  final EnhancementSettings settings;
  final bool isProcessing;
  final String? resultPath;
  final String? error;

  const EnhancementState({
    this.settings = const EnhancementSettings(),
    this.isProcessing = false,
    this.resultPath,
    this.error,
  });

  EnhancementState copyWith({
    EnhancementSettings? settings,
    bool? isProcessing,
    String? resultPath,
    String? error,
  }) {
    return EnhancementState(
      settings: settings ?? this.settings,
      isProcessing: isProcessing ?? this.isProcessing,
      resultPath: resultPath ?? this.resultPath,
      error: error,
    );
  }
}

class EnhancementController extends StateNotifier<EnhancementState> {
  final Ref ref;
  EnhancementController(this.ref) : super(const EnhancementState());

  void update(EnhancementSettings Function(EnhancementSettings) apply) {
    state = state.copyWith(settings: apply(state.settings), resultPath: null);
  }

  Future<void> preview(String sourcePath) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final output = await ref
          .read(enhancementServiceProvider)
          .enhance(sourcePath, state.settings);
      state = state.copyWith(isProcessing: false, resultPath: output);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<void> saveAsNewVersion(RecordingEntity recording) async {
    if (state.resultPath == null) return;
    final updated = recording.copyWith(enhancedPath: state.resultPath);
    await ref.read(recordingUsecasesProvider).save(updated);
  }
}

final StateNotifierProvider<EnhancementController, EnhancementState>
    enhancementControllerProvider =
    StateNotifierProvider<EnhancementController, EnhancementState>(
  (ref) => EnhancementController(ref),
);
