import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/record_controller.dart';

class RecordControls extends StatelessWidget {
  final RecordStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const RecordControls({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (status == RecordStatus.idle) {
      return _RecordButton(onTap: onStart);
    }

    final isPaused = status == RecordStatus.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.close_rounded,
          onTap: onCancel,
          background: Theme.of(context).colorScheme.surfaceContainerHighest,
          iconColor: Theme.of(context).colorScheme.onSurface,
          size: 56,
        ),
        const SizedBox(width: 24),
        _CircleButton(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          onTap: isPaused ? onResume : onPause,
          background: AppColors.primary,
          iconColor: Colors.white,
          size: 72,
        ),
        const SizedBox(width: 24),
        _CircleButton(
          icon: Icons.stop_rounded,
          onTap: onStop,
          background: AppColors.accent,
          iconColor: Colors.white,
          size: 56,
        ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CircleButton(
      icon: Icons.mic_rounded,
      onTap: onTap,
      background: AppColors.primary,
      iconColor: Colors.white,
      size: 88,
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.iconColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }
}
