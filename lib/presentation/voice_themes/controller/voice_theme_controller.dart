import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../shared/recording_mutations.dart';

class VoiceThemeState {
  final VoiceTheme? selected;
  final bool isProcessing;
  final Map<VoiceTheme, String> previews;
  final String? error;

  const VoiceThemeState({
    this.selected,
    this.isProcessing = false,
    this.previews = const {},
    this.error,
  });

  VoiceThemeState copyWith({
    VoiceTheme? selected,
    bool? isProcessing,
    Map<VoiceTheme, String>? previews,
    String? error,
  }) {
    return VoiceThemeState(
      selected: selected ?? this.selected,
      isProcessing: isProcessing ?? this.isProcessing,
      previews: previews ?? this.previews,
      error: error,
    );
  }
}

class VoiceThemeController extends StateNotifier<VoiceThemeState> {
  final Ref ref;
  VoiceThemeController(this.ref) : super(const VoiceThemeState());

  Future<void> preview(RecordingEntity recording, VoiceTheme theme) async {
    state = state.copyWith(selected: theme, isProcessing: true, error: null);
    try {
      final existing = state.previews[theme];
      final path = existing ??
          await ref.read(voiceThemeServiceProvider).applyTheme(
                recording.localPath,
                theme,
                sampleRate: recording.sampleRate,
              );
      final updatedPreviews = Map<VoiceTheme, String>.from(state.previews)
        ..[theme] = path;
      state = state.copyWith(isProcessing: false, previews: updatedPreviews);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<bool> save(RecordingEntity recording, VoiceTheme theme) async {
    final path = state.previews[theme];
    if (path == null) return false;
    final saved = await saveRecordingPatch(
      ref,
      recording.id,
      (current) => current.copyWith(
        themeVariants: Map<VoiceTheme, String>.from(current.themeVariants)
          ..[theme] = path,
      ),
    );
    return saved != null;
  }
}

final StateNotifierProvider<VoiceThemeController, VoiceThemeState>
    voiceThemeControllerProvider =
    StateNotifierProvider<VoiceThemeController, VoiceThemeState>(
  (ref) => VoiceThemeController(ref),
);
