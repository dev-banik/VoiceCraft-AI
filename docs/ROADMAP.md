# Roadmap

## Shipped in this build

- Clean Architecture (domain/data/services/presentation), Riverpod DI throughout
- Hive local persistence, hand-written TypeAdapters (build_runner-compatible)
- Recording: WAV/MP3(AAC container)/AAC, 44.1/48kHz, standard/high/studio bitrate presets, live waveform + volume meter + duration counter, pause/resume
- Dashboard: totals, recent activity, storage usage, per-recording sync status
- Noise Removal: FFmpeg spectral-denoise pipeline, strength slider, A/B compare
- Voice Themes: all 10 spec'd presets via pitch/formant DSP, original never touched, preview-before-save
- Clarity Enhancement: vocal boost / EQ / compression / loudness normalization / speech enhancement, each independently tunable
- Editor: trim, split (saves two new recordings), delete segment, copy segment (new recording), fade in/out, volume adjust, pinch-zoom + drag-select waveform
- Playback: speed control (0.5x–2x), loop, source switching (original/denoised/enhanced/theme)
- Google Sign-In (only auth path, per spec), Firestore metadata sync, Storage audio sync, lazy audio download on multi-device pull, WorkManager background sync
- Search with name query + Noise Removed / Theme Applied / Synced / Local Only filters
- Settings: recording defaults, default voice theme, backup toggles, storage usage, light/dark/system theme
- Firestore + Storage security rules scoped per-uid
- GitHub Actions CI building installable release + debug APKs on every push

## Explicitly deferred (see reasoning in each doc)

- **Real neural noise removal / voice conversion** (RNNoise/Demucs/Silero/RVC/So-VITS-SVC) — see [AI_PIPELINE.md](AI_PIPELINE.md). The `AiEngine` seam is in place; this is the highest-value next investment.
- **Whisper transcription** — spec marks this optional; no transcription UI exists yet. Would slot in as a new `services/ai/transcription_service.dart` + a caption/transcript panel on the Playback screen.
- **Signed iOS build / TestFlight pipeline** — needs your Apple Developer credentials; see [DEPLOYMENT.md](DEPLOYMENT.md#4-ios--running-on-a-device).
- **Play Store-signed Android release in CI** — needs your upload keystore as a CI secret; see [DEPLOYMENT.md](DEPLOYMENT.md#2-android--release-signing-for-play-store).
- **Encrypted local metadata at rest** — the spec's Security Requirements call for this; Hive boxes aren't yet opened with `HiveAesCipher`. Straightforward follow-up: add `flutter_secure_storage` (to hold the encryption key) and `hive` already supports `Hive.openBox(..., encryptionCipher: HiveAesCipher(key))` in `hive_boxes.dart`.
- **Localization** — Settings has a language field in the data model; no `.arb` files / `flutter_localizations` wiring yet.
- **Widget/integration test coverage** — `test/unit/` covers pure-Dart utilities only; controllers and screens have no automated tests yet (they need fakes for `record`/`just_audio`/Firebase, which is real setup work, not a quick add).
- **App icon / splash branding** — ships with the default Flutter launcher icon; see the Play Store checklist in [DEPLOYMENT.md](DEPLOYMENT.md).
