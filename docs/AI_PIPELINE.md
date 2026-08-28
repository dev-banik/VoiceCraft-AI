# AI Pipeline

## What ships today

`services/ai/` implements three modules, all behind the `AiEngine`
interface (`services/ai/ai_engine.dart`):

- `NoiseRemovalService` — noise removal
- `VoiceThemeService` — the 10 voice themes
- `AudioEnhancementService` — Clarity Enhancement

All three are built on **FFmpeg audio filters**, run on-device via
`ffmpeg_kit_flutter_new`'s bundled binaries. No model download, no network
call, no cloud inference — everything happens locally, which also means it
works fully offline.

- **Noise removal**: `highpass` (rumble) → `afftdn` (FFT spectral
  denoiser, this is the actual noise-reduction stage) → `anlmdn`
  (non-local-means smoothing) → `acompressor` (evens out the result so
  suppression doesn't leave the voice sounding thin). The strength slider
  maps onto `afftdn`'s dB reduction amount and `anlmdn`'s smoothing
  strength.
- **Voice themes**: pitch shift via the classic `asetrate` →
  `aresample` → `atempo` chain (bends pitch by re-declaring the sample
  rate, then resamples back and compensates tempo so duration is
  preserved), layered with theme-specific coloring — `bass`/`treble`/
  `equalizer` for timbre, `vibrato`/`tremolo` for wobble (old voice,
  cartoon), `flanger` + `acrusher` for a digital/robotic edge, `chorus` for
  mimicry, `aecho` + bandpass for radio-presenter coloring.
- **Clarity Enhancement**: `highpass` (speech enhancement) →
  `equalizer` (presence/EQ) → `volume` (vocal boost) → `acompressor`
  (compression) → `loudnorm` (EBU R128 loudness normalization), each stage
  gated by its own 0–1 slider.

This is genuinely functional DSP — it audibly reduces noise and audibly
changes voice character — but it is signal processing, not learned/neural
transformation. It will not sound like a different, specific human voice
the way RVC/So-VITS-SVC does, and it will not out-perform a trained RNNoise/
Demucs model on hard noise (multi-talker babble, non-stationary noise).

## Why not the neural models named in the spec

RNNoise, Demucs, Silero, RVC, So-VITS-SVC and Whisper all need **trained
model weights** (RNNoise's are small and bundleable; Demucs/Silero/RVC are
tens to hundreds of MB and task/voice-specific). Fetching, converting
(to TFLite/ONNX), and validating those on real device hardware wasn't
possible in the environment this repo was built in — there's no GPU, no
model registry access, and no way to verify inference correctness or
latency without a real device. Shipping an untested, unverified model
integration would be worse than shipping a working DSP MVP with an honest
label.

## Upgrade path

The `AiEngine` interface + one provider binding per service in
`core/di/providers.dart` (`noiseRemovalServiceProvider`,
`voiceThemeServiceProvider`, `enhancementServiceProvider`) is the seam:

1. Add `tflite_flutter` or `onnxruntime` to `pubspec.yaml`.
2. Bundle the model under `assets/models/` (already declared in
   `pubspec.yaml`'s `flutter.assets`).
3. Implement a new class satisfying the same public method signature as the
   service you're replacing (`removeNoise(path, strength)`,
   `applyTheme(path, theme, sampleRate)`, `enhance(path, settings)`) —
   internally it loads the interpreter, runs inference on decoded PCM, and
   writes the result to a new file exactly like the FFmpeg version does.
4. Swap the provider binding in `core/di/providers.dart` to construct your
   new class instead. No screen, controller, or usecase changes — they all
   depend on the method signature, not the implementation.

Recommended order if you pick this up: **RNNoise via TFLite for noise
removal first** (smallest model, most tractable, biggest perceptible
quality jump over `afftdn`), then **Silero VAD** to gate the denoiser so it
doesn't process silence, then voice themes last — RVC/So-VITS-SVC are the
most complex integration (they need a reference voice/checkpoint per theme,
not just one general-purpose model).
