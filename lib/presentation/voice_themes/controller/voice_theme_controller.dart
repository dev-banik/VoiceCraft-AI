import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../../services/ai/processed_media.dart';
import '../../shared/recording_mutations.dart';

class VoiceThemeState {
  final VoiceTheme? selected;
  final bool isProcessing;
  final Map<VoiceTheme, ProcessedMedia> previews;
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
    Map<VoiceTheme, ProcessedMedia>? previews,
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

  /// Clears the chosen theme and stops the preview.
  ///
  /// Needs its own method because `copyWith` can't put `selected` back to
  /// null — `selected ?? this.selected` keeps the old value — so once a
  /// theme was picked there was no way to un-pick it.
  void clearSelection() {
    ref.read(audioPlayerServiceProvider).stop();
    state = VoiceThemeState(previews: state.previews);
  }

  Future<void> preview(RecordingEntity recording, VoiceTheme theme) async {
    state = state.copyWith(selected: theme, isProcessing: true, error: null);
    try {
      final existing = state.previews[theme];
      final processed = existing ??
          await ref.read(voiceThemeServiceProvider).applyTheme(
                recording.localPath,
                theme,
                sampleRate: recording.sampleRate,
              );
      final updatedPreviews =
          Map<VoiceTheme, ProcessedMedia>.from(state.previews)
            ..[theme] = processed;
      state = state.copyWith(isProcessing: false, previews: updatedPreviews);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  /// Stores the themed take, either over [recording] or as its own entry.
  /// Returns the id of the recording to show afterwards, or null if nothing
  /// was saved.
  Future<String?> save(
    RecordingEntity recording,
    VoiceTheme theme,
    DerivativeSaveMode mode,
  ) async {
    final processed = state.previews[theme];
    if (processed == null) return null;
    return saveDerivative(
      ref,
      recordingId: recording.id,
      processedPath: processed.path,
      companionAudioPath: processed.audioPath,
      titleSuffix: theme.label,
      mode: mode,
      mark: (r, p) => r.copyWith(
        themeVariants: Map<VoiceTheme, String>.from(r.themeVariants)
          ..[theme] = p,
      ),
    );
  }
}

final StateNotifierProvider<VoiceThemeController, VoiceThemeState>
    voiceThemeControllerProvider =
    StateNotifierProvider<VoiceThemeController, VoiceThemeState>(
  (ref) => VoiceThemeController(ref),
);
