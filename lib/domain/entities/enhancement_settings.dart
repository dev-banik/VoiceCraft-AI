import 'package:equatable/equatable.dart';

/// User-tunable parameters for the Clarity Enhancement module.
/// All values are 0.0-1.0 sliders; the service layer maps them onto
/// concrete FFmpeg filter parameters (see `AudioEnhancementService`).
class EnhancementSettings extends Equatable {
  final double clarity;
  final double vocalBoost;
  final double eq;
  final double compression;
  final double loudnessNormalization;
  final double speechEnhancement;

  const EnhancementSettings({
    this.clarity = 0.5,
    this.vocalBoost = 0.0,
    this.eq = 0.0,
    this.compression = 0.0,
    this.loudnessNormalization = 0.5,
    this.speechEnhancement = 0.0,
  });

  EnhancementSettings copyWith({
    double? clarity,
    double? vocalBoost,
    double? eq,
    double? compression,
    double? loudnessNormalization,
    double? speechEnhancement,
  }) {
    return EnhancementSettings(
      clarity: clarity ?? this.clarity,
      vocalBoost: vocalBoost ?? this.vocalBoost,
      eq: eq ?? this.eq,
      compression: compression ?? this.compression,
      loudnessNormalization:
          loudnessNormalization ?? this.loudnessNormalization,
      speechEnhancement: speechEnhancement ?? this.speechEnhancement,
    );
  }

  @override
  List<Object?> get props => [
        clarity,
        vocalBoost,
        eq,
        compression,
        loudnessNormalization,
        speechEnhancement,
      ];
}
