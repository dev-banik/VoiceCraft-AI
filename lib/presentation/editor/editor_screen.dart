import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../playback/controller/playback_controller.dart';
import 'controller/editor_controller.dart';
import 'widgets/interactive_waveform.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String recordingId;
  const EditorScreen({super.key, required this.recordingId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    final recordingAsync =
        ref.watch(recordingByIdProvider(widget.recordingId));
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    ref.listen(editorControllerProvider, (previous, next) {
      if (next.statusMessage != null &&
          next.statusMessage != previous?.statusMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.statusMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Editor')),
      body: recordingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('Recording not found.'));
          }
          final waveformAsync =
              ref.watch(waveformSamplesProvider(recording.localPath));
          final position =
              ref.watch(playbackPositionProvider).valueOrNull ?? Duration.zero;
          final progress = recording.duration.inMilliseconds == 0
              ? 0.0
              : (position.inMilliseconds / recording.duration.inMilliseconds)
                  .clamp(0.0, 1.0);

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.duration(
                          state.selection.startDuration(recording.duration),
                        ),
                      ),
                      Text(
                        Formatters.duration(
                          state.selection.endDuration(recording.duration),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: waveformAsync.when(
                    loading: () => const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(height: 140),
                    data: (samples) => InteractiveWaveform(
                      samples: samples,
                      selection: state.selection,
                      zoom: state.zoom,
                      playbackProgress: progress,
                      onSelectionChanged: controller.setSelection,
                      onZoomChanged: controller.setZoom,
                      onSeek: (frac) {
                        final target = Duration(
                          milliseconds:
                              (recording.duration.inMilliseconds * frac)
                                  .round(),
                        );
                        ref
                            .read(playbackControllerProvider)
                            .seek(target);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () async {
                    await ref
                        .read(playbackControllerProvider)
                        .load(recording.localPath);
                    await ref.read(playbackControllerProvider).playPause(false);
                  },
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
                const Divider(height: 1),
                Expanded(
                  child: state.isBusy
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                          padding: const EdgeInsets.all(20),
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _ToolButton(
                              icon: Icons.content_cut_rounded,
                              label: 'Trim to selection',
                              onTap: () => controller.trim(recording),
                            ),
                            _ToolButton(
                              icon: Icons.call_split_rounded,
                              label: 'Split here',
                              onTap: () =>
                                  controller.splitAtSelectionStart(recording),
                            ),
                            _ToolButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete selection',
                              onTap: () => controller.deleteSelection(recording),
                            ),
                            _ToolButton(
                              icon: Icons.copy_rounded,
                              label: 'Copy selection',
                              onTap: () => controller
                                  .copySegmentAsNewRecording(recording),
                            ),
                            _ToolButton(
                              icon: Icons.trending_up_rounded,
                              label: 'Fade in',
                              onTap: () => controller.fadeIn(
                                recording,
                                const Duration(seconds: 2),
                              ),
                            ),
                            _ToolButton(
                              icon: Icons.trending_down_rounded,
                              label: 'Fade out',
                              onTap: () => controller.fadeOut(
                                recording,
                                const Duration(seconds: 2),
                              ),
                            ),
                            _ToolButton(
                              icon: Icons.volume_up_rounded,
                              label: 'Volume +3dB',
                              onTap: () =>
                                  controller.adjustVolume(recording, 3),
                            ),
                            _ToolButton(
                              icon: Icons.volume_down_rounded,
                              label: 'Volume -3dB',
                              onTap: () =>
                                  controller.adjustVolume(recording, -3),
                            ),
                          ],
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

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
