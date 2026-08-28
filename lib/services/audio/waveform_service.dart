import 'package:audio_waveforms/audio_waveforms.dart';

/// Extracts downsampled amplitude data from an audio file for the static
/// waveform views (dashboard tile preview, playback screen, editor). The
/// live in-progress waveform during recording is driven directly by
/// [AudioRecorderService.ticks] instead, since there is no file to read
/// from yet.
class WaveformService {
  Future<List<double>> extract(String path, {int samplesPerSecond = 100}) async {
    final controller = PlayerController();
    try {
      final waveformData = await controller.extractWaveformData(
        path: path,
        noOfSamples: samplesPerSecond * 60, // up to ~60s of resolution
      );
      return waveformData;
    } finally {
      controller.dispose();
    }
  }
}
