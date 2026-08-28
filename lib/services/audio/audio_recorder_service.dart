import 'dart:async';

import 'package:record/record.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permission_utils.dart';

/// Snapshot of recorder state emitted while a take is in progress, used to
/// drive the waveform, duration counter and input volume meter on the
/// Record screen.
class RecorderTick {
  final Duration elapsed;
  final double amplitudeDb;

  const RecorderTick({required this.elapsed, required this.amplitudeDb});
}

/// Wraps the `record` package with app-specific format/quality mapping and
/// pause/resume support. One instance is shared for the lifetime of the app
/// via Riverpod.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<RecorderTick>? _tickController;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  String? _currentPath;

  Stream<RecorderTick> get ticks =>
      (_tickController ??= StreamController<RecorderTick>.broadcast())
          .stream;

  bool get isRecording => _stopwatch.isRunning;

  Future<String> start({
    required RecordingFormat format,
    required int sampleRate,
    required RecordingQuality quality,
  }) async {
    final granted = await PermissionUtils.requestMicrophone();
    if (!granted) {
      throw const PermissionDeniedException('Microphone permission denied.');
    }

    final extension = _extensionFor(format);
    final path = await FileUtils.newRecordingPath(extension);

    final config = RecordConfig(
      encoder: _encoderFor(format),
      sampleRate: sampleRate,
      bitRate: _bitRateFor(quality),
      numChannels: 1,
    );

    try {
      await _recorder.start(config, path: path);
    } catch (e) {
      throw RecordingException('Failed to start recording: $e');
    }

    _currentPath = path;
    _stopwatch
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amp = await _recorder.getAmplitude();
      (_tickController ??= StreamController<RecorderTick>.broadcast()).add(
        RecorderTick(elapsed: _stopwatch.elapsed, amplitudeDb: amp.current),
      );
    });

    return path;
  }

  Future<void> pause() async {
    await _recorder.pause();
    _stopwatch.stop();
  }

  Future<void> resume() async {
    await _recorder.resume();
    _stopwatch.start();
  }

  Future<String?> stop() async {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    final path = await _recorder.stop();
    final result = path ?? _currentPath;
    _currentPath = null;
    return result;
  }

  Future<void> cancel() async {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    await _recorder.cancel();
    if (_currentPath != null) {
      await FileUtils.delete(_currentPath!);
    }
    _currentPath = null;
  }

  void dispose() {
    _timer?.cancel();
    _tickController?.close();
    _recorder.dispose();
  }

  AudioEncoder _encoderFor(RecordingFormat format) {
    switch (format) {
      case RecordingFormat.wav:
        return AudioEncoder.wav;
      case RecordingFormat.mp3:
        return AudioEncoder.aacLc; // encoded then remuxed by editor service
      case RecordingFormat.aac:
        return AudioEncoder.aacLc;
    }
  }

  String _extensionFor(RecordingFormat format) {
    switch (format) {
      case RecordingFormat.wav:
        return 'wav';
      case RecordingFormat.mp3:
        return 'm4a'; // source capture; converted to mp3 on export if needed
      case RecordingFormat.aac:
        return 'm4a';
    }
  }

  int _bitRateFor(RecordingQuality quality) {
    switch (quality) {
      case RecordingQuality.standard:
        return 96000;
      case RecordingQuality.high:
        return 192000;
      case RecordingQuality.studio:
        return 320000;
    }
  }
}
