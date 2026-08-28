import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/enhancement_settings.dart';
import 'ai_engine.dart';

/// Clarity Enhancement module — vocal boost, EQ, compression, loudness
/// normalization and speech enhancement, all driven by one 0-100 "Clarity"
/// slider plus the finer per-effect sliders in [EnhancementSettings].
class AudioEnhancementService implements AiEngine {
  @override
  String get engineName => 'FFmpeg Clarity Chain v1';

  @override
  bool get requiresModel => false;

  Future<String> enhance(
    String sourcePath,
    EnhancementSettings settings,
  ) async {
    final output = await FileUtils.derivedPath(sourcePath, 'enhanced');
    final filter = _buildFilterChain(settings);

    final cmd = '-y -i "$sourcePath" -af "$filter" "$output"';
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final logs = await session.getAllLogsAsString();
      appLogger.e('Enhancement failed: $logs');
      throw AudioProcessingException('Clarity enhancement failed.');
    }
    return output;
  }

  String _buildFilterChain(EnhancementSettings s) {
    final stages = <String>[];

    // Speech enhancement: tighten the vocal band, cut rumble/hiss outside it.
    if (s.speechEnhancement > 0) {
      final hp = 60 + s.speechEnhancement * 40; // 60-100 Hz
      stages.add('highpass=f=${hp.toStringAsFixed(0)}');
    }

    // EQ: gentle presence boost around 2-4kHz for intelligibility.
    if (s.eq > 0) {
      final gain = s.eq * 8; // up to +8dB
      stages.add('equalizer=f=3000:t=q:w=1.2:g=${gain.toStringAsFixed(1)}');
    }

    // Vocal boost: overall gain applied to the voice band.
    if (s.vocalBoost > 0) {
      final gain = s.vocalBoost * 6; // up to +6dB
      stages.add('volume=${gain.toStringAsFixed(1)}dB');
    }

    // Compression: evens out level swings.
    if (s.compression > 0) {
      final ratio = 1 + s.compression * 5; // 1:1 to 6:1
      stages.add(
        'acompressor=threshold=-20dB:ratio=${ratio.toStringAsFixed(1)}:'
        'attack=10:release=200:makeup=2',
      );
    }

    // Loudness normalization: EBU R128 two-pass-quality single-pass filter.
    if (s.loudnessNormalization > 0) {
      final target = -23 + s.loudnessNormalization * 9; // -23 to -14 LUFS
      stages.add('loudnorm=I=${target.toStringAsFixed(1)}:TP=-1.5:LRA=11');
    }

    if (stages.isEmpty) return 'anull';
    return stages.join(',');
  }
}
