import 'package:audio_waveforms/audio_waveforms.dart';

import '../../core/utils/logger.dart';

/// Extracts downsampled amplitude data from an audio file for the static
/// waveform views (dashboard tile preview, playback screen, editor). The
/// live in-progress waveform during recording is driven directly by
/// [AudioRecorderService.ticks] instead, since there is no file to read
/// from yet.
class WaveformService {
  /// Enough detail to read the shape of a take on a phone-width screen.
  /// This used to ask for 6000 samples, which meant decoding the whole file
  /// at high resolution before anything could be drawn — seconds of spinner
  /// on the playback screen for a picture a few hundred pixels wide.
  static const int _defaultSamples = 240;

  /// Extraction opens its own player under the hood and occasionally never
  /// completes on a file the platform decoder dislikes. A waveform is
  /// decoration; it must not be able to hang the screen.
  static const Duration _timeout = Duration(seconds: 6);

  Future<List<double>> extract(String path, {int? noOfSamples}) async {
    final controller = PlayerController();
    try {
      return await controller
          .extractWaveformData(
            path: path,
            noOfSamples: noOfSamples ?? _defaultSamples,
          )
          .timeout(_timeout);
    } catch (e) {
      // An empty list renders as a flat line rather than an error state:
      // not being able to draw the waveform is no reason to stop someone
      // playing the recording.
      appLogger.w('Waveform extraction failed for $path: $e');
      return const <double>[];
    } finally {
      controller.dispose();
    }
  }
}
