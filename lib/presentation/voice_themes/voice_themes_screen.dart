import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/route_names.dart';
import '../playback/controller/playback_controller.dart';
import '../shared/recording_mutations.dart';
import '../shared/widgets/save_mode_dialog.dart';
import 'controller/voice_theme_controller.dart';
import 'widgets/theme_card.dart';

const List<VoiceTheme> _selectableThemes = [
  VoiceTheme.childVoice,
  VoiceTheme.youngFemale,
  VoiceTheme.youngMale,
  VoiceTheme.cartoonVoice,
  VoiceTheme.robotVoice,
  VoiceTheme.mimicryStyle,
  VoiceTheme.deepVoice,
  VoiceTheme.oldVoice,
  VoiceTheme.animeVoice,
  VoiceTheme.radioPresenter,
];

class VoiceThemesScreen extends ConsumerWidget {
  final String recordingId;
  const VoiceThemesScreen({super.key, required this.recordingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingAsync = ref.watch(recordingByIdProvider(recordingId));
    final state = ref.watch(voiceThemeControllerProvider);
    final controller = ref.read(voiceThemeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Themes')),
      body: recordingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('Recording not found.'));
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Your original recording is never modified — each theme '
                    'creates a new, separate file.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _selectableThemes.length,
                    itemBuilder: (context, i) {
                      final theme = _selectableThemes[i];
                      return ThemeCard(
                        theme: theme,
                        selected: state.selected == theme,
                        isProcessing: state.isProcessing,
                        hasPreview: state.previews.containsKey(theme),
                        onTap: () async {
                          await controller.preview(recording, theme);
                          final path = ref
                              .read(voiceThemeControllerProvider)
                              .previews[theme];
                          if (path != null) {
                            final player = ref.read(playbackControllerProvider);
                            await player.load(path);
                            await player.playPause(false);
                          }
                        },
                      );
                    },
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.selected == null ||
                              !state.previews.containsKey(state.selected)
                          ? null
                          : () async {
                              final voiceTheme = state.selected!;
                              final mode = await showSaveModeDialog(
                                context,
                                what: '${voiceTheme.label} version',
                              );
                              if (mode == null || !context.mounted) return;

                              final targetId = await controller.save(
                                recording,
                                voiceTheme,
                                mode,
                              );
                              if (!context.mounted) return;
                              if (targetId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Couldn't save that take."),
                                  ),
                                );
                                return;
                              }
                              if (mode == DerivativeSaveMode.replace) {
                                Navigator.pop(context, ThemeSource(voiceTheme));
                              } else {
                                context.pushReplacement(
                                  RoutePaths.playbackPath(targetId),
                                );
                              }
                            },
                      child: const Text('Save as new version'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
