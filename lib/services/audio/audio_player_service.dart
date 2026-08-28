import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

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
    await session.configure(const AudioSessionConfiguration.speech());
    _sessionConfigured = true;
  }

  Future<void> loadFile(String path) async {
    await _ensureSession();
    await _player.setFilePath(path);
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
