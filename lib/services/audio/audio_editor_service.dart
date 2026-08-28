import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';

/// Waveform-editor primitives (trim / split / delete-segment / copy-segment
/// / fade / volume / merge), implemented on top of the FFmpeg binaries
/// bundled by `ffmpeg_kit_flutter_new`. Every operation reads the source
/// file and writes a new derived file — the original recording is never
/// mutated in place, matching the "original audio always remains untouched"
/// requirement for theming and the general non-destructive editing model.
class AudioEditorService {
  Future<void> _run(String command, String opName) async {
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      appLogger.e('$opName failed: $logs');
      throw AudioProcessingException('$opName failed (ffmpeg exit $returnCode).');
    }
  }

  /// Cuts everything outside [start, end] and writes a new file.
  Future<String> trim(
    String sourcePath, {
    required Duration start,
    required Duration end,
  }) async {
    final output = await FileUtils.derivedPath(sourcePath, 'trim');
    final duration = end - start;
    final cmd = '-y -i "$sourcePath" -ss ${start.inMilliseconds / 1000} '
        '-t ${duration.inMilliseconds / 1000} -c copy "$output"';
    await _run(cmd, 'Trim');
    return output;
  }

  /// Splits [sourcePath] at [at] into two new files: (partA, partB).
  Future<(String, String)> split(String sourcePath, Duration at) async {
    final partA = await FileUtils.derivedPath(sourcePath, 'partA');
    final partB = await FileUtils.derivedPath(sourcePath, 'partB');
    final atSeconds = at.inMilliseconds / 1000;

    await _run(
      '-y -i "$sourcePath" -t $atSeconds -c copy "$partA"',
      'Split (part A)',
    );
    await _run(
      '-y -i "$sourcePath" -ss $atSeconds -c copy "$partB"',
      'Split (part B)',
    );
    return (partA, partB);
  }

  /// Removes [start, end] from the middle of the recording and concatenates
  /// what remains into one continuous file.
  Future<String> deleteSegment(
    String sourcePath, {
    required Duration start,
    required Duration end,
  }) async {
    final output = await FileUtils.derivedPath(sourcePath, 'cut');
    final filter = "aselect='not(between(t,${start.inMilliseconds / 1000},"
        "${end.inMilliseconds / 1000}))',asetpts=N/SR/TB";
    final cmd = '-y -i "$sourcePath" -af "$filter" "$output"';
    await _run(cmd, 'Delete segment');
    return output;
  }

  /// Extracts [start, end] into a standalone file, leaving the source
  /// untouched (used for "copy segment").
  Future<String> copySegment(
    String sourcePath, {
    required Duration start,
    required Duration end,
  }) {
    return trim(sourcePath, start: start, end: end);
  }

  Future<String> fadeIn(String sourcePath, Duration duration) async {
    final output = await FileUtils.derivedPath(sourcePath, 'fadein');
    final cmd = '-y -i "$sourcePath" -af '
        '"afade=t=in:st=0:d=${duration.inMilliseconds / 1000}" "$output"';
    await _run(cmd, 'Fade in');
    return output;
  }

  Future<String> fadeOut(
    String sourcePath,
    Duration duration,
    Duration totalDuration,
  ) async {
    final output = await FileUtils.derivedPath(sourcePath, 'fadeout');
    final start =
        (totalDuration - duration).inMilliseconds / 1000;
    final cmd = '-y -i "$sourcePath" -af '
        '"afade=t=out:st=$start:d=${duration.inMilliseconds / 1000}" "$output"';
    await _run(cmd, 'Fade out');
    return output;
  }

  /// [gainDb] is added gain in decibels; negative attenuates, positive boosts.
  Future<String> adjustVolume(String sourcePath, double gainDb) async {
    final output = await FileUtils.derivedPath(sourcePath, 'volume');
    final cmd = '-y -i "$sourcePath" -af "volume=${gainDb}dB" "$output"';
    await _run(cmd, 'Volume adjustment');
    return output;
  }

  /// Concatenates multiple clips (e.g. rejoining after a delete/split flow)
  /// into a single output file. All inputs must share codec/sample rate.
  Future<String> merge(List<String> sourcePaths, String extension) async {
    final output = await FileUtils.newRecordingPath(extension);
    final listFile = File('${output}_list.txt');
    final content = sourcePaths
        .map((p) => "file '${p.replaceAll("'", "'\\''")}'")
        .join('\n');
    await listFile.writeAsString(content);

    final cmd = '-y -f concat -safe 0 -i "${listFile.path}" -c copy "$output"';
    try {
      await _run(cmd, 'Merge');
    } finally {
      if (await listFile.exists()) {
        await listFile.delete();
      }
    }
    return output;
  }

  /// Reads exact duration of a media file, used after edits to refresh
  /// stored metadata.
  Future<Duration> probeDuration(String path) async {
    final session = await FFmpegKit.execute(
      '-y -i "$path" -f null -',
    );
    final output = await session.getAllLogsAsString() ?? '';
    final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.\d+)').firstMatch(output);
    if (match == null) return Duration.zero;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final s = double.parse(match.group(3)!);
    return Duration(
      hours: h,
      minutes: m,
      milliseconds: (s * 1000).round(),
    );
  }
}
