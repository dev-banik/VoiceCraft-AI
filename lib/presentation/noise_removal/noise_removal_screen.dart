import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../playback/controller/playback_controller.dart';
import 'controller/noise_removal_controller.dart';

class NoiseRemovalScreen extends ConsumerStatefulWidget {
  final String recordingId;
  const NoiseRemovalScreen({super.key, required this.recordingId});

  @override
  ConsumerState<NoiseRemovalScreen> createState() =>
      _NoiseRemovalScreenState();
}

class _NoiseRemovalScreenState extends ConsumerState<NoiseRemovalScreen> {
  bool _playingProcessed = false;

  @override
  Widget build(BuildContext context) {
    final recordingAsync =
        ref.watch(recordingByIdProvider(widget.recordingId));
    final state =
        ref.watch(noiseRemovalControllerProvider(widget.recordingId));
    final controller =
        ref.read(noiseRemovalControllerProvider(widget.recordingId).notifier);

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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Removes traffic, wind, fans, keyboard clicks and '
                    'background chatter while keeping your voice natural.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Strength',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: state.strength,
                    onChanged: controller.setStrength,
                    label: '${(state.strength * 100).round()}%',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${(state.strength * 100).round()}%'),
                  ),
                  const SizedBox(height: 12),
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
                        state.isProcessing ? 'Processing…' : 'Process audio',
                      ),
                      onPressed: state.isProcessing
                          ? null
                          : () => controller.process(recording.localPath),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (state.resultPath != null) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Compare',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Original')),
                        ButtonSegment(value: true, label: Text('Processed')),
                      ],
                      selected: {_playingProcessed},
                      onSelectionChanged: (selection) async {
                        final processed = selection.first;
                        setState(() => _playingProcessed = processed);
                        final path = processed
                            ? state.resultPath!
                            : recording.localPath;
                        final player = ref.read(playbackControllerProvider);
                        await player.load(path);
                        await player.playPause(false);
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await controller.save(recording);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save as noise-removed version'),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
