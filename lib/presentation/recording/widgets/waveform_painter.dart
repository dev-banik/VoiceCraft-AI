import 'package:flutter/material.dart';

/// Live bar-style waveform painter for the Record screen, driven by the
/// rolling amplitude list in [RecordState.waveform] (0..1 normalized).
class LiveWaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color activeColor;
  final Color inactiveColor;

  LiveWaveformPainter({
    required this.samples,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      final paint = Paint()
        ..color = inactiveColor
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final list = samples.toList();
    final barWidth = size.width / list.length;
    final paint = Paint()..color = activeColor;

    for (var i = 0; i < list.length; i++) {
      final amplitude = list[i].clamp(0.05, 1.0);
      final barHeight = size.height * amplitude;
      final x = i * barWidth;
      final rect = Rect.fromLTWH(
        x,
        (size.height - barHeight) / 2,
        (barWidth - 2).clamp(1, barWidth),
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LiveWaveformPainter oldDelegate) => true;
}
