import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/recording_entity.dart';

/// Which derived audio source is currently loaded for playback: the
/// original take, the noise-removed version, or a specific voice theme.
sealed class PlaybackSource {
  const PlaybackSource();
}

class OriginalSource extends PlaybackSource {
  const OriginalSource();
}

class DenoisedSource extends PlaybackSource {
  const DenoisedSource();
}

class EnhancedSource extends PlaybackSource {
  const EnhancedSource();
}

class ThemeSource extends PlaybackSource {
  final VoiceTheme theme;
  const ThemeSource(this.theme);
}

/// Fetches a recording and, for one pulled down from another device via
/// cloud sync (metadata present locally, audio not downloaded yet — see
/// `SyncRepositoryImpl.syncAll`), lazily downloads the audio the first time
/// it's needed rather than eagerly fetching every synced recording's audio
/// up front. Every screen that opens a recording (playback, noise removal,
/// themes, enhancement, editor) reads the recording through this provider,
/// so this one lazy-download path covers all of them.
final FutureProvider.family<RecordingEntity?, String> recordingByIdProvider =
    FutureProvider.family<RecordingEntity?, String>((ref, id) async {
  final result = await ref.read(recordingUsecasesProvider).getById(id);
  final recording = result.valueOrNull;
  if (recording == null) return null;

  final localFile = File(recording.localPath);
  if (await localFile.exists() || recording.cloudUrl == null) {
    return recording;
  }

  try {
    await ref.read(storageDatasourceProvider).download(
          cloudUrl: recording.cloudUrl!,
          destinationPath: recording.localPath,
        );
  } catch (e) {
    appLogger.w('Lazy audio download failed for $id: $e');
  }
  return recording;
});

final StreamProvider<Duration> playbackPositionProvider =
    StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerServiceProvider).positionStream;
});

final StreamProvider<PlayerState> playbackStateProvider =
    StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerServiceProvider).stateStream;
});

final FutureProvider.family<List<double>, String> waveformSamplesProvider =
    FutureProvider.family<List<double>, String>((ref, path) {
  return ref.read(waveformServiceProvider).extract(path);
});

class PlaybackController {
  final Ref ref;
  const PlaybackController(this.ref);

  Future<void> load(String path) async {
    await ref.read(audioPlayerServiceProvider).loadFile(path);
  }

  Future<void> playPause(bool isPlaying) async {
    final service = ref.read(audioPlayerServiceProvider);
    if (isPlaying) {
      await service.pause();
    } else {
      await service.play();
    }
  }

  Future<void> seek(Duration position) =>
      ref.read(audioPlayerServiceProvider).seek(position);

  Future<void> setSpeed(double speed) =>
      ref.read(audioPlayerServiceProvider).setSpeed(speed);

  Future<void> setLoop(bool loop) =>
      ref.read(audioPlayerServiceProvider).setLoop(loop);
}

final Provider<PlaybackController> playbackControllerProvider =
    Provider((ref) => PlaybackController(ref));
