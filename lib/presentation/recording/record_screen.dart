import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import 'controller/record_controller.dart';
import 'widgets/record_controls.dart';
import 'widgets/volume_meter.dart';
import 'widgets/waveform_painter.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  @override
  void dispose() {
    final status = ref.read(recordControllerProvider).status;
    if (status == RecordStatus.recording || status == RecordStatus.paused) {
      ref.read(recordControllerProvider.notifier).cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);
    final controller = ref.read(recordControllerProvider.notifier);

    ref.listen(recordControllerProvider, (previous, next) {
      if (next.status == RecordStatus.stopped &&
          next.finishedRecordingId != null) {
        context.pushReplacement(
          RoutePaths.playbackPath(next.finishedRecordingId!),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('New Recording')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                Formatters.duration(state.elapsed),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                switch (state.status) {
                  RecordStatus.idle => 'Tap to start recording',
                  RecordStatus.recording => 'Recording…',
                  RecordStatus.paused => 'Paused',
                  RecordStatus.stopped => 'Saved',
                },
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: LiveWaveformPainter(
                    samples: state.waveform,
                    activeColor: AppColors.waveformActive,
                    inactiveColor: AppColors.waveformInactive,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              VolumeMeter(amplitudeDb: state.amplitudeDb),
              const Spacer(),
              RecordControls(
                status: state.status,
                onStart: controller.start,
                onPause: controller.pause,
                onResume: controller.resume,
                onStop: controller.stop,
                onCancel: () {
                  controller.cancel();
                  context.pop();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
