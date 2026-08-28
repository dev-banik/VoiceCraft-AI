import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../settings/controller/settings_controller.dart';

enum RecordStatus { idle, recording, paused, stopped }

class RecordState {
  final RecordStatus status;
  final Duration elapsed;
  final double amplitudeDb;
  final List<double> waveform;
  final String? finishedRecordingId;

  const RecordState({
    this.status = RecordStatus.idle,
    this.elapsed = Duration.zero,
    this.amplitudeDb = -60,
    this.waveform = const <double>[],
    this.finishedRecordingId,
  });

  RecordState copyWith({
    RecordStatus? status,
    Duration? elapsed,
    double? amplitudeDb,
    List<double>? waveform,
    String? finishedRecordingId,
  }) {
    return RecordState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      amplitudeDb: amplitudeDb ?? this.amplitudeDb,
      waveform: waveform ?? this.waveform,
      finishedRecordingId: finishedRecordingId ?? this.finishedRecordingId,
    );
  }
}

const int _maxWaveformSamples = 120;

class RecordController extends StateNotifier<RecordState> {
  final Ref ref;
  StreamSubscription? _tickSub;

  RecordController(this.ref) : super(const RecordState());

  Future<void> start() async {
    final settings = ref.read(settingsControllerProvider);
    final service = ref.read(audioRecorderServiceProvider);

    await service.start(
      format: RecordingFormat.values.byName(settings.recordingFormat),
      sampleRate: settings.sampleRate,
      quality: RecordingQuality.values.byName(settings.recordingQuality),
    );

    state = const RecordState(status: RecordStatus.recording);

    _tickSub = service.ticks.listen((tick) {
      final wave = List<double>.from(state.waveform)
        ..add(_normalize(tick.amplitudeDb));
      while (wave.length > _maxWaveformSamples) {
        wave.removeAt(0);
      }
      state = state.copyWith(
        elapsed: tick.elapsed,
        amplitudeDb: tick.amplitudeDb,
        waveform: wave,
        status: RecordStatus.recording,
      );
    });
  }

  double _normalize(double db) {
    // Typical mic amplitude ranges roughly -45dB (quiet) to 0dB (clipping);
    // clamp+normalize to 0..1 for the waveform painter.
    final clamped = db.clamp(-45.0, 0.0);
    return (clamped + 45) / 45;
  }

  Future<void> pause() async {
    await ref.read(audioRecorderServiceProvider).pause();
    state = state.copyWith(status: RecordStatus.paused);
  }

  Future<void> resume() async {
    await ref.read(audioRecorderServiceProvider).resume();
    state = state.copyWith(status: RecordStatus.recording);
  }

  Future<void> stop() async {
    final path = await ref.read(audioRecorderServiceProvider).stop();
    await _tickSub?.cancel();

    if (path == null) {
      state = state.copyWith(status: RecordStatus.idle);
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    final size = await FileUtils.sizeOf(path);

    final recording = RecordingEntity(
      id: FileUtils.newId(),
      title: 'Recording ${_defaultTitleSuffix()}',
      localPath: path,
      duration: state.elapsed,
      sizeBytes: size,
      createdAt: DateTime.now(),
      format: RecordingFormat.values.byName(settings.recordingFormat),
      sampleRate: settings.sampleRate,
      quality: RecordingQuality.values.byName(settings.recordingQuality),
    );

    await ref.read(recordingUsecasesProvider).save(recording);

    state = state.copyWith(
      status: RecordStatus.stopped,
      finishedRecordingId: recording.id,
    );
  }

  Future<void> cancel() async {
    await ref.read(audioRecorderServiceProvider).cancel();
    await _tickSub?.cancel();
    state = const RecordState();
  }

  String _defaultTitleSuffix() {
    final now = DateTime.now();
    return '${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<RecordController, RecordState>
    recordControllerProvider =
    StateNotifierProvider<RecordController, RecordState>(
  (ref) => RecordController(ref),
);
