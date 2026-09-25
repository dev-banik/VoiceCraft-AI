import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/router/route_names.dart';
import '../../domain/entities/recording_entity.dart';
import '../playback/controller/playback_controller.dart';
import '../shared/recording_mutations.dart';
import '../shared/widgets/save_mode_dialog.dart';
import 'controller/noise_removal_controller.dart';

class NoiseRemovalScreen extends ConsumerStatefulWidget {
  final String recordingId;
  const NoiseRemovalScreen({super.key, required this.recordingId});

  @override
  ConsumerState<NoiseRemovalScreen> createState() =>
      _NoiseRemovalScreenState();
}

class _NoiseRemovalScreenState extends ConsumerState<NoiseRemovalScreen> {
  bool _playingProcessed = true;

  @override
  void dispose() {
    // Same shared player as everywhere else: without this, an A/B preview
    // carries on playing after the screen is gone.
    ref.read(audioPlayerServiceProvider).stop();
    super.dispose();
  }

  /// Loads whichever side of the comparison is selected and starts it, so
  /// switching between Original and Processed plays straight away instead of
  /// needing a second tap.
  Future<void> _playSide(bool processed, RecordingEntity recording) async {
    final state = ref.read(noiseRemovalControllerProvider(widget.recordingId));

    // This comparison is about how the voice sounds, so it always plays
    // audio. For a video the processed result is an .mp4 the audio engine
    // can't drive — which is why "cleaned" was silent — so use the
    // soundtrack that was extracted alongside it.
    final path = processed
        ? (state.resultAudioPath ?? state.resultPath)
        : (state.sourceAudioPath ?? recording.localPath);
    if (path == null) return;

    try {
      final player = ref.read(playbackControllerProvider);
      await player.load(path);
      await player.playPause(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't play that: $e")),
      );
    }
  }

  Future<void> _save(RecordingEntity recording) async {
    final controller =
        ref.read(noiseRemovalControllerProvider(widget.recordingId).notifier);

    final mode = await showSaveModeDialog(
      context,
      what: 'noise-removed audio',
    );
    if (mode == null || !mounted) return;

    final targetId = await controller.save(recording, mode);
    if (!mounted) return;

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the processed audio.")),
      );
      return;
    }

    await ref.read(playbackControllerProvider).playPause(true);
    if (!mounted) return;

    if (mode == DerivativeSaveMode.replace) {
      // Same recording, now holding the processed audio — hand the Versions
      // row back so playback lands on it.
      Navigator.pop(context, const DenoisedSource());
    } else {
      // A separate recording now exists; go to it rather than back to the
      // untouched source the user was just on.
      context.pushReplacement(RoutePaths.playbackPath(targetId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordingAsync =
        ref.watch(recordingByIdProvider(widget.recordingId));
    final state =
        ref.watch(noiseRemovalControllerProvider(widget.recordingId));
    final controller =
        ref.read(noiseRemovalControllerProvider(widget.recordingId).notifier);
    final isPlaying =
        ref.watch(playbackStateProvider).valueOrNull?.playing ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Noise Removal')),
      body: recordingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('Recording not found.'));
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              recording.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Removes traffic, wind, fans, keyboard clicks and '
                        'background chatter while keeping your voice natural.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Strength',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${(state.strength * 100).round()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: state.strength,
                        onChanged:
                            state.isProcessing ? null : controller.setStrength,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gentle', style: theme.textTheme.bodySmall),
                          Text('Aggressive', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Higher strength removes more background, but can '
                        'start to thin out your voice.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: state.isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_rounded),
                          label: Text(
                            state.isProcessing
                                ? 'Processing…'
                                : state.resultPath == null
                                    ? 'Process audio'
                                    : 'Process again',
                          ),
                          onPressed: state.isProcessing
                              ? null
                              : () => controller.process(recording.localPath),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  _Card(
                    color: theme.colorScheme.errorContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.resultPath != null) ...[
                  const SizedBox(height: 16),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Listen to both before you decide.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.mic_none_rounded),
                                label: Text('Before'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.auto_awesome_rounded),
                                label: Text('After'),
                              ),
                            ],
                            selected: {_playingProcessed},
                            onSelectionChanged: (selection) {
                              setState(
                                () => _playingProcessed = selection.first,
                              );
                              _playSide(selection.first, recording);
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: FilledButton.tonalIcon(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              isPlaying
                                  ? 'Pause'
                                  : _playingProcessed
                                      ? 'Play noise-removed version'
                                      : 'Play the original',
                            ),
                            onPressed: () async {
                              if (isPlaying) {
                                await ref
                                    .read(playbackControllerProvider)
                                    .playPause(true);
                              } else {
                                await _playSide(_playingProcessed, recording);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save noise-removed audio'),
                      onPressed: () => _save(recording),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You choose whether it replaces this recording or is '
                    'saved as a new one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _Card({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
