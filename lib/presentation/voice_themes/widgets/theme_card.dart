import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

const Map<VoiceTheme, IconData> _themeIcons = {
  VoiceTheme.childVoice: Icons.child_care_rounded,
  VoiceTheme.youngFemale: Icons.face_3_rounded,
  VoiceTheme.youngMale: Icons.face_rounded,
  VoiceTheme.cartoonVoice: Icons.emoji_emotions_rounded,
  VoiceTheme.robotVoice: Icons.smart_toy_rounded,
  VoiceTheme.mimicryStyle: Icons.record_voice_over_rounded,
  VoiceTheme.deepVoice: Icons.graphic_eq_rounded,
  VoiceTheme.oldVoice: Icons.elderly_rounded,
  VoiceTheme.animeVoice: Icons.auto_awesome_rounded,
  VoiceTheme.radioPresenter: Icons.radio_rounded,
};

class ThemeCard extends StatelessWidget {
  final VoiceTheme theme;
  final bool selected;
  final bool isProcessing;
  final bool hasPreview;
  final VoidCallback onTap;

  const ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.isProcessing,
    required this.hasPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.12) : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (selected && isProcessing)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _themeIcons[theme] ?? Icons.graphic_eq_rounded,
                  size: 28,
                  color: selected ? AppColors.primary : scheme.onSurfaceVariant,
                ),
              const SizedBox(height: 10),
              Text(
                theme.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (hasPreview) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
