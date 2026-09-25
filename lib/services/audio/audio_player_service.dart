import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Thrown when a recording's file cannot be opened for playback, so the UI
/// can say so instead of showing a dead transport that ignores every tap.
class AudioLoadException implements Exception {
  final String message;
  const AudioLoadException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around `just_audio` configured for speech/voice playback
/// (proper AudioSession category so recordings duck other audio correctly
/// on both platforms). Used by the Playback screen and the A/B compare UI
/// in Noise Removal / Voice Themes.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _sessionConfigured = false;

  AudioPlayer get player => _player;

  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    // `music()`, not `speech()`. The speech profile asks Android for
    // voice-communication routing, which sends audio to the earpiece — so
    // playback ran with nothing audible coming out of the loudspeaker.
    // These are recordings being listened back to, i.e. media.
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  /// Loads [path] and waits until the player actually reports a duration.
  ///
  /// `setFilePath` resolving does not by itself mean the source is playable;
  /// calling play() too early left the player sitting at 0:00 ignoring both
  /// play and seek. Returns the duration, or null if the file could not be
  /// loaded at all.
  Future<Duration?> loadFile(String path) async {
    await _ensureSession();
    try {
      final duration = await _player.setFilePath(path);
      return duration ?? _player.duration;
    } catch (e) {
      throw AudioLoadException('Could not open this recording: $e');
    }
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setLoop(bool loop) =>
      _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  Stream<PlayerState> get stateStream => _player.playerStateStream;

  Future<void> dispose() => _player.dispose();
}
