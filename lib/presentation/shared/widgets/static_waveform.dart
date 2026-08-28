import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Non-interactive amplitude waveform used on the Playback screen. Bars
/// before [progress] render in the active color to show playhead position;
/// [selection] (0..1 start/end, optional) is used by the Editor screen to
/// additionally highlight a trim/selection range on top of the same visual.
class StaticWaveform extends StatelessWidget {
  final List<double> samples;
  final double progress;
  final (double, double)? selection;
  final double height;

  const StaticWaveform({
    super.key,
    required this.samples,
    this.progress = 0,
    this.selection,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StaticWaveformPainter(
          samples: samples,
          progress: progress,
          selection: selection,
        ),
      ),
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final (double, double)? selection;

  _StaticWaveformPainter({
    required this.samples,
    required this.progress,
    required this.selection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barWidth = size.width / samples.length;
    final playedPaint = Paint()..color = AppColors.waveformActive;
    final unplayedPaint = Paint()..color = AppColors.waveformInactive;
    final selectionPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12);

    if (selection != null) {
      final (start, end) = selection!;
      canvas.drawRect(
        Rect.fromLTWH(
          start * size.width,
          0,
          (end - start) * size.width,
          size.height,
        ),
        selectionPaint,
      );
    }

    for (var i = 0; i < samples.length; i++) {
      final amplitude = samples[i].clamp(0.02, 1.0);
      final barHeight = size.height * amplitude;
      final x = i * barWidth;
      final isPlayed = (i / samples.length) <= progress;
      final rect = Rect.fromLTWH(
        x,
        (size.height - barHeight) / 2,
        (barWidth - 1.5).clamp(1, barWidth),
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        isPlayed ? playedPaint : unplayedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StaticWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples ||
        oldDelegate.selection != selection;
  }
}
