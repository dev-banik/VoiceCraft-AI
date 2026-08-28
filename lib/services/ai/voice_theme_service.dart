import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';
import 'ai_engine.dart';

/// Voice Themes pipeline: Original Recording -> Select Theme
/// -> Generate New Version -> Save as Separate File. The source recording
/// is opened read-only and never overwritten, matching the spec's
/// "original audio must always remain untouched" requirement.
///
/// This MVP engine builds each theme from FFmpeg DSP primitives:
///   - Pitch shift without changing duration: `asetrate` (re-declare the
///     sample rate to bend pitch) -> `aresample` back to the real rate
///     -> `atempo=1/factor` to cancel the resulting speed change.
///   - Timbre/character: `equalizer`/`bass`/`treble` shaping, `vibrato` /
///     `tremolo` for wobble, `flanger` + `acrusher` for a robotic/digital
///     edge, `aecho` for a radio/PA colour.
///
/// It is genuinely audible and functional, not a stub — but it is signal
/// processing, not neural timbre transfer. For studio-grade "sounds like a
/// different person" conversion, swap in RVC/So-VITS-SVC per-theme models
/// behind this same [applyTheme] signature (see docs/AI_PIPELINE.md).
class VoiceThemeService implements AiEngine {
  @override
  String get engineName => 'FFmpeg Pitch/Formant DSP v1';

  @override
  bool get requiresModel => false;

  Future<String> applyTheme(
    String sourcePath,
    VoiceTheme theme, {
    int sampleRate = AppConstants.defaultSampleRate,
  }) async {
    if (theme == VoiceTheme.original) return sourcePath;

    final output = await FileUtils.derivedPath(sourcePath, theme.name);
    final filter = _filterChainFor(theme, sampleRate);

    final cmd = '-y -i "$sourcePath" -af "$filter" "$output"';
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final logs = await session.getAllLogsAsString();
      appLogger.e('Voice theme (${theme.name}) failed: $logs');
      throw AudioProcessingException('Applying ${theme.label} failed.');
    }
    return output;
  }

  /// Builds an `asetrate`-based pitch shift that preserves duration.
  /// [semitones] positive = higher pitch, negative = lower pitch.
  String _pitchShift(double semitones, {required int sourceRate}) {
    final factor = _semitoneToFactor(semitones);
    final newRate = (sourceRate * factor).round();
    final tempoCompensation = 1 / factor;
    // atempo only supports 0.5-2.0 per stage; chain two stages for extreme
    // shifts (child/anime themes) so the tempo correction stays in range.
    final tempoFilters = _chainedAtempo(tempoCompensation);
    return 'asetrate=$newRate,aresample=$sourceRate,$tempoFilters';
  }

  double _semitoneToFactor(double semitones) => math.pow(2, semitones / 12).toDouble();

  String _chainedAtempo(double factor) {
    var remaining = factor;
    final stages = <String>[];
    while (remaining > 2.0) {
      stages.add('atempo=2.0');
      remaining /= 2.0;
    }
    while (remaining < 0.5) {
      stages.add('atempo=0.5');
      remaining /= 0.5;
    }
    stages.add('atempo=${remaining.toStringAsFixed(4)}');
    return stages.join(',');
  }

  String _filterChainFor(VoiceTheme theme, int sr) {
    switch (theme) {
      case VoiceTheme.original:
        return 'anull';

      case VoiceTheme.childVoice:
        return '${_pitchShift(6, sourceRate: sr)},treble=g=4,highpass=f=150';

      case VoiceTheme.youngFemale:
        return '${_pitchShift(4, sourceRate: sr)},treble=g=3';

      case VoiceTheme.youngMale:
        return '${_pitchShift(-2, sourceRate: sr)},bass=g=2,treble=g=1';

      case VoiceTheme.cartoonVoice:
        return '${_pitchShift(8, sourceRate: sr)},vibrato=f=6:d=0.4,'
            'treble=g=5';

      case VoiceTheme.robotVoice:
        return '${_pitchShift(-1, sourceRate: sr)},flanger=delay=0:depth=2:'
            'regen=0:width=71:speed=0.6:shape=triangular,acrusher=bits=8:'
            'mode=log:aa=0.5,equalizer=f=1200:t=q:w=1:g=6';

      case VoiceTheme.mimicryStyle:
        return '${_pitchShift(3, sourceRate: sr)},chorus=0.6:0.9:55:0.4:'
            '0.25:2,equalizer=f=2000:t=q:w=1:g=3';

      case VoiceTheme.deepVoice:
        return '${_pitchShift(-5, sourceRate: sr)},bass=g=6,treble=g=-2';

      case VoiceTheme.oldVoice:
        return '${_pitchShift(-1, sourceRate: sr)},vibrato=f=4.5:d=0.25,'
            'treble=g=-4,tremolo=f=5:d=0.3';

      case VoiceTheme.animeVoice:
        return '${_pitchShift(7, sourceRate: sr)},treble=g=6,'
            'equalizer=f=3000:t=q:w=1:g=4';

      case VoiceTheme.radioPresenter:
        return 'highpass=f=300,lowpass=f=3400,'
            'acompressor=threshold=-18dB:ratio=4:attack=5:release=100:'
            'makeup=4,aecho=0.8:0.7:20:0.15,equalizer=f=1500:t=q:w=1:g=4';
    }
  }
}
