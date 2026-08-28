import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';
import 'ai_engine.dart';

/// AI Noise Removal pipeline:
///   Input Audio -> Noise Detection -> AI Noise Suppression
///   -> Voice Enhancement -> Output Audio
///
/// Detection: FFmpeg's `afftdn` estimates the noise floor from the first
/// ~0.5s of audio (adjustable) rather than requiring a separate silent
/// noise-print step, so it works on a single continuous take.
/// Suppression: `afftdn` (FFT denoiser) + `anlmdn` (non-local means
/// denoiser) run in series, tuned by [strength].
/// Voice enhancement: a speech-band highpass + gentle compressor so
/// suppression doesn't leave the voice sounding thin or robotic.
///
/// [strength] is 0.0-1.0 and maps onto `afftdn`'s noise-reduction amount and
/// `anlmdn`'s smoothing strength, so the UI slider has an audible effect
/// across its whole range without ever fully gating the voice.
class NoiseRemovalService implements AiEngine {
  @override
  String get engineName => 'FFmpeg Spectral Denoise v1';

  @override
  bool get requiresModel => false;

  Future<String> removeNoise(
    String sourcePath, {
    double strength = 0.6,
  }) async {
    final clamped = strength.clamp(0.0, 1.0);
    final output = await FileUtils.derivedPath(sourcePath, 'denoised');

    // afftdn noise-reduction range is roughly 0.01-97 dB; anlmdn strength is
    // 0.00001-10000, both non-linear, so we map the 0-1 slider onto usable
    // sub-ranges rather than the full documented range.
    final nr = 6 + clamped * 34; // ~6dB (barely on) to 40dB (aggressive)
    final nlStrength = 0.0001 + clamped * 0.01;

    final filter = [
      'highpass=f=80',
      'afftdn=nr=$nr:nf=-25',
      'anlmdn=s=$nlStrength',
      'acompressor=threshold=-21dB:ratio=2.5:attack=8:release=180:makeup=2',
    ].join(',');

    final cmd = '-y -i "$sourcePath" -af "$filter" "$output"';
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final logs = await session.getAllLogsAsString();
      appLogger.e('Noise removal failed: $logs');
      throw AudioProcessingException('Noise removal failed.');
    }
    return output;
  }
}
