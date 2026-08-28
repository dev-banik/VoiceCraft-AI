import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Horizontal input-level meter driven by the recorder's amplitude in dB
/// (roughly -45 quiet .. 0 clipping).
class VolumeMeter extends StatelessWidget {
  final double amplitudeDb;

  const VolumeMeter({super.key, required this.amplitudeDb});

  @override
  Widget build(BuildContext context) {
    final level = ((amplitudeDb.clamp(-45.0, 0.0) + 45) / 45).clamp(0.0, 1.0);
    final isHot = amplitudeDb > -6;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: level,
        minHeight: 10,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(
          isHot ? AppColors.warning : AppColors.secondary,
        ),
      ),
    );
  }
}
