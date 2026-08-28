/// Pluggable AI backend contract shared by noise removal and voice theming.
///
/// This app ships a working `FfmpegDspEngine` (see `noise_removal_service.dart`
/// / `voice_theme_service.dart`) built entirely on production FFmpeg audio
/// filters — spectral denoise, EQ, compression, pitch/formant shifting.
/// It runs fully on-device with no model downloads and no network calls,
/// and is what "AI Noise Removal" / "Voice Themes" mean out of the box.
///
/// To upgrade to true neural inference (RNNoise/Demucs/Silero for denoise,
/// RVC/So-VITS-SVC for voice conversion), implement this interface against
/// `tflite_flutter` or `onnxruntime` with a bundled/downloaded model, and
/// swap the provider binding in `core/di/providers.dart` — no call site
/// outside that binding needs to change. See docs/AI_PIPELINE.md.
abstract class AiEngine {
  /// Human-readable identifier shown in Settings/About (e.g.
  /// "FFmpeg DSP v1" vs "RNNoise (TFLite)").
  String get engineName;

  /// Whether this engine requires a model file/network access to run.
  bool get requiresModel;
}
