import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../playback/controller/playback_controller.dart';
import 'controller/enhancement_controller.dart';

class EnhancementScreen extends ConsumerWidget {
  final String recordingId;
  const EnhancementScreen({super.key, required this.recordingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingAsync = ref.watch(recordingByIdProvider(recordingId));
    final state = ref.watch(enhancementControllerProvider);
    final controller = ref.read(enhancementControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Clarity Enhancement')),
      body: recordingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('Recording not found.'));
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ClaritySlider(
                  label: 'Vocal Boost',
                  value: state.settings.vocalBoost,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(vocalBoost: v)),
                ),
                _ClaritySlider(
                  label: 'EQ (presence)',
                  value: state.settings.eq,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(eq: v)),
                ),
                _ClaritySlider(
                  label: 'Compression',
                  value: state.settings.compression,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(compression: v)),
                ),
                _ClaritySlider(
                  label: 'Loudness Normalization',
                  value: state.settings.loudnessNormalization,
                  onChanged: (v) => controller
                      .update((s) => s.copyWith(loudnessNormalization: v)),
                ),
                _ClaritySlider(
                  label: 'Speech Enhancement',
                  value: state.settings.speechEnhancement,
                  onChanged: (v) => controller
                      .update((s) => s.copyWith(speechEnhancement: v)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: state.isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    state.isProcessing ? 'Processing…' : 'Preview',
                  ),
                  onPressed: state.isProcessing
                      ? null
                      : () async {
                          await controller.preview(recording.localPath);
                          final path = ref
                              .read(enhancementControllerProvider)
                              .resultPath;
                          if (path != null) {
                            final player = ref.read(playbackControllerProvider);
                            await player.load(path);
                            await player.playPause(false);
                          }
                        },
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
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await controller.saveAsNewVersion(recording);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save as enhanced version'),
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

class _ClaritySlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _ClaritySlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text('${(value * 100).round()}'),
            ],
          ),
          Slider(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
